module Account::Chartable
  extend ActiveSupport::Concern

  class_methods do
    def balance_series(currency:, period: Period.last_30_days, favorable_direction: "up")
      balances = Account::Balance.find_by_sql([
        balance_series_query,
        {
          start_date: period.start_date,
          end_date: period.end_date,
          interval: period.interval,
          target_currency: currency
        }
      ])

      Series.new(
        start_date: period.start_date,
        end_date: period.end_date,
        interval: period.interval,
        trend: Trend.new(
          current: Money.new(balances.last&.balance || 0, currency),
          previous: Money.new(balances.first&.balance || 0, currency),
          favorable_direction: favorable_direction
        ),
        values: balances.map do |balance|
          Series::Value.new(
            date: balance.date,
            date_formatted: I18n.l(balance.date, format: :short),
            trend: Trend.new(
              current: Money.new(balance.balance, currency),
              previous: Money.new(balance.prior_balance, currency),
              favorable_direction: favorable_direction
            )
          )
        end
      )
    end

    private
      def balance_series_query
        <<~SQL
          WITH dates as (
            SELECT generate_series(DATE :start_date, DATE :end_date, :interval::interval)::date as date
          ), balances as (
            SELECT
              d.date,
              COALESCE(SUM(ab.balance * COALESCE(er.rate, 1)), 0) as balance,
              COUNT(CASE WHEN accounts.currency <> :target_currency AND er.rate IS NULL THEN 1 END) as missing_rates
            FROM dates d
            LEFT JOIN accounts ON accounts.id IN (#{all.select(:id).to_sql})
            LEFT JOIN account_balances ab ON (
              ab.date = d.date AND
              ab.currency = accounts.currency AND
              ab.account_id = accounts.id
            )
            LEFT JOIN exchange_rates er ON (
              er.date = ab.date AND
              er.from_currency = accounts.currency AND
              er.to_currency = :target_currency
            )
            GROUP BY d.date
            ORDER BY d.date
          )
          SELECT
            balances.date,
            COALESCE(balances.balance, 0) as balance,
            COALESCE(LAG(balances.balance, 1) OVER (ORDER BY date), 0) as prior_balance,
            balances.missing_rates
          FROM balances
          ORDER BY date
        SQL
      end
  end

  def favorable_direction
    classification == "asset" ? "up" : "down"
  end

  def balance_series(period: Period.last_30_days)
    self.class.where(id: self.id).balance_series(
      currency: currency,
      period: period,
      favorable_direction: favorable_direction
    )
  end
end
