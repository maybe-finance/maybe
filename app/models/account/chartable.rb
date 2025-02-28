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

      balances = gapfill_balances(balances)
      balances = invert_balances(balances) if favorable_direction == "down"

      values = [ nil, *balances ].each_cons(2).map do |prev, curr|
        Series::Value.new(
          date: curr.date,
          date_formatted: I18n.l(curr.date, format: :long),
          trend: Trend.new(
            current: Money.new(curr.balance, currency),
            previous: prev.nil? ? nil : Money.new(prev.balance, currency),
            favorable_direction: favorable_direction
          )
        )
      end

      Series.new(
        start_date: period.start_date,
        end_date: period.end_date,
        interval: period.interval,
        trend: Trend.new(
          current: Money.new(balances.last&.balance || 0, currency),
          previous: Money.new(balances.first&.balance || 0, currency),
          favorable_direction: favorable_direction
        ),
        values: values
      )
    end

    private
      def balance_series_query
        <<~SQL
          WITH dates as (
            SELECT generate_series(DATE :start_date, DATE :end_date, :interval::interval)::date as date
            UNION DISTINCT
            SELECT CURRENT_DATE -- Ensures we always end on current date, regardless of interval
          )
          SELECT
            d.date,
            SUM(CASE WHEN accounts.classification = 'asset' THEN ab.balance ELSE -ab.balance END * COALESCE(er.rate, 1)) as balance,
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
        SQL
      end

      def invert_balances(balances)
        balances.map do |balance|
          balance.balance = -balance.balance
          balance
        end
      end

      def gapfill_balances(balances)
        gapfilled = []

        prev_balance = nil

        [ nil, *balances ].each_cons(2).each_with_index do |(prev, curr), index|
          if index == 0 && curr.balance.nil?
            curr.balance = 0 # Ensure all series start with a non-nil balance
          elsif curr.balance.nil?
            curr.balance = prev.balance
          end

          gapfilled << curr
        end

        gapfilled
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
