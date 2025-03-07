module Account::Chartable
  extend ActiveSupport::Concern

  class_methods do
    def cash_balance_series(currency:, period: Period.last_30_days, favorable_direction: "up")
      generate_series(
        balances: fetch_balances(currency: currency, period: period),
        period: period,
        currency: currency,
        favorable_direction: favorable_direction,
        balance_type: :cash_balance
      )
    end

    def holdings_series(currency:, period: Period.last_30_days, favorable_direction: "up")
      generate_series(
        balances: fetch_balances(currency: currency, period: period),
        period: period,
        currency: currency,
        favorable_direction: favorable_direction,
        balance_type: :holdings_balance
      )
    end

    def balance_series(currency:, period: Period.last_30_days, favorable_direction: "up")
      generate_series(
        balances: fetch_balances(currency: currency, period: period),
        period: period,
        currency: currency,
        favorable_direction: favorable_direction,
        balance_type: :balance
      )
    end

    private
      def fetch_balances(currency:, period:)
        @_memoized_balances ||= {}
        cache_key = "#{currency}_#{period.start_date}_#{period.end_date}_#{period.interval}"

        @_memoized_balances[cache_key] ||= Account::Balance.find_by_sql([
          balance_series_query,
          {
            start_date: period.start_date,
            end_date: period.end_date,
            interval: period.interval,
            target_currency: currency
          }
        ])
      end

      def generate_series(balances:, period:, currency:, favorable_direction:, balance_type:)
        balances = gapfill_balances(balances, balance_type)
        balances = invert_balances(balances, balance_type) if favorable_direction == "down"

        values = [ nil, *balances ].each_cons(2).map do |prev, curr|
          Series::Value.new(
            date: curr.date,
            date_formatted: I18n.l(curr.date, format: :long),
            trend: Trend.new(
              current: Money.new(curr.send(balance_type), currency),
              previous: prev.nil? ? nil : Money.new(prev.send(balance_type), currency),
              favorable_direction: favorable_direction
            )
          )
        end

        Series.new(
          start_date: period.start_date,
          end_date: period.end_date,
          interval: period.interval,
          trend: Trend.new(
            current: Money.new(balances.last&.send(balance_type) || 0, currency),
            previous: Money.new(balances.first&.send(balance_type) || 0, currency),
            favorable_direction: favorable_direction
          ),
          values: values
        )
      end

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
            SUM(CASE WHEN accounts.classification = 'asset' THEN ab.cash_balance ELSE -ab.cash_balance END * COALESCE(er.rate, 1)) as cash_balance,
            SUM(CASE WHEN accounts.classification = 'asset' THEN ab.balance - ab.cash_balance ELSE 0 END * COALESCE(er.rate, 1)) as holdings_balance,
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

      def invert_balances(balances, balance_type)
        balances.map do |balance|
          balance.send("#{balance_type}=", -balance.send(balance_type))
          balance
        end
      end

      def gapfill_balances(balances, balance_type)
        gapfilled = []

        [ nil, *balances ].each_cons(2).each_with_index do |(prev, curr), index|
          if index == 0 && curr.send(balance_type).nil?
            curr.send("#{balance_type}=", 0) # Ensure all series start with a non-nil balance
          elsif curr.send(balance_type).nil?
            curr.send("#{balance_type}=", prev.send(balance_type))
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

  def sparkline_series
    cache_key = family.build_cache_key("#{id}_sparkline")

    Rails.cache.fetch(cache_key) do
      balance_series
    end
  end
end
