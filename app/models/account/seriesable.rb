module Account::Seriesable
  extend ActiveSupport::Concern

  class_methods do
    def series(currency:, period: Period.last_30_days, favorable_direction: "up")
      query = <<~SQL
        WITH dates as (
          SELECT generate_series(DATE :start_date, GREATEST(DATE :end_date, CURRENT_DATE), :interval::interval)::date as date
        ), balances as (
          SELECT
            d.date,
            COALESCE(SUM(ab.balance * COALESCE(er.rate, 1)), 0) as balance,
            COUNT(CASE WHEN a.currency <> :target_currency AND er.rate IS NULL THEN 1 END) as missing_rates
          FROM dates d
          LEFT JOIN accounts a ON a.id IN (:account_ids)
          LEFT JOIN account_balances ab ON (
            ab.date = d.date AND
            ab.currency = a.currency AND
            ab.account_id = a.id
          )
          LEFT JOIN exchange_rates er ON (
            er.date = ab.date AND
            er.from_currency = a.currency AND
            er.to_currency = :target_currency
          )
          GROUP BY d.date
          ORDER BY d.date
        )
        SELECT
          balances.date,
          balances.balance,
          LAG(balances.balance, 1) OVER (ORDER BY date) as prior_balance,
          balances.missing_rates
        FROM balances
      SQL

      balances = Account::Balance.find_by_sql([
        query,
        {
          account_ids: all.pluck(:id),
          start_date: period.start_date,
          end_date: period.end_date,
          interval: period.interval,
          target_currency: currency
        }
      ]).map do |balance|
        balance.define_singleton_method(:balance_money) do
          Money.new(balance.balance, currency)
        end

        balance
      end

      TimeSeries.from_collection(balances, :balance_money)
    end
  end
end
