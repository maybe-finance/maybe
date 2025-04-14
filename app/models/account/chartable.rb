module Account::Chartable
  extend ActiveSupport::Concern

  class_methods do
    def balance_series(currency:, period: Period.last_30_days, favorable_direction: "up", view: :balance, interval: nil)
      raise ArgumentError, "Invalid view type" unless [ :balance, :cash_balance, :holdings_balance ].include?(view.to_sym)

      series_interval = interval || period.interval

      balances = Balance.find_by_sql([
        balance_series_query,
        {
          start_date: period.start_date,
          end_date: period.end_date,
          interval: series_interval,
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
            current: Money.new(balance_value_for(curr, view), currency),
            previous: prev.nil? ? nil : Money.new(balance_value_for(prev, view), currency),
            favorable_direction: favorable_direction
          )
        )
      end

      Series.new(
        start_date: period.start_date,
        end_date: period.end_date,
        interval: series_interval,
        trend: Trend.new(
          current: Money.new(balance_value_for(balances.last, view) || 0, currency),
          previous: Money.new(balance_value_for(balances.first, view) || 0, currency),
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
            SUM(CASE WHEN accounts.classification = 'asset' THEN ab.cash_balance ELSE -ab.cash_balance END * COALESCE(er.rate, 1)) as cash_balance,
            SUM(CASE WHEN accounts.classification = 'asset' THEN ab.balance - ab.cash_balance ELSE 0 END * COALESCE(er.rate, 1)) as holdings_balance,
            COUNT(CASE WHEN accounts.currency <> :target_currency AND er.rate IS NULL THEN 1 END) as missing_rates
          FROM dates d
          LEFT JOIN accounts ON accounts.id IN (#{all.select(:id).to_sql})
          LEFT JOIN balances ab ON (
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

      def balance_value_for(balance_record, view)
        return 0 if balance_record.nil?

        case view.to_sym
        when :balance then balance_record.balance
        when :cash_balance then balance_record.cash_balance
        when :holdings_balance then balance_record.holdings_balance
        else
          raise ArgumentError, "Invalid view type: #{view}"
        end
      end

      def invert_balances(balances)
        balances.map do |balance|
          balance.balance = -balance.balance
          balance.cash_balance = -balance.cash_balance
          balance.holdings_balance = -balance.holdings_balance
          balance
        end
      end

      def gapfill_balances(balances)
        gapfilled = []
        prev = nil

        balances.each do |curr|
          if prev.nil?
            # Initialize first record with zeros if nil
            curr.balance ||= 0
            curr.cash_balance ||= 0
            curr.holdings_balance ||= 0
          else
            # Copy previous values for nil fields
            curr.balance ||= prev.balance
            curr.cash_balance ||= prev.cash_balance
            curr.holdings_balance ||= prev.holdings_balance
          end

          gapfilled << curr
          prev = curr
        end

        gapfilled
      end
  end

  def favorable_direction
    classification == "asset" ? "up" : "down"
  end

  def balance_series(period: Period.last_30_days, view: :balance, interval: nil)
    self.class.where(id: self.id).balance_series(
      currency: currency,
      period: period,
      view: view,
      interval: interval,
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
