class Balance::ChartSeriesBuilder
  def initialize(account_ids:, currency:, period: Period.last_30_days, interval: "1 day", favorable_direction: "up")
    @account_ids = account_ids
    @currency = currency
    @period = period
    @interval = interval
    @favorable_direction = favorable_direction
  end

  def balance_series
    build_series_for(:balance)
  rescue => e
    Rails.logger.error "Balance series error: #{e.message} for accounts #{@account_ids}"
    raise
  end

  def cash_balance_series
    build_series_for(:cash_balance)
  rescue => e
    Rails.logger.error "Cash balance series error: #{e.message} for accounts #{@account_ids}"
    raise
  end

  def holdings_balance_series
    build_series_for(:holdings_balance)
  rescue => e
    Rails.logger.error "Holdings balance series error: #{e.message} for accounts #{@account_ids}"
    raise
  end

  private
    attr_reader :account_ids, :currency, :period, :favorable_direction

    def interval
      @interval || period.interval
    end

    def build_series_for(column)
      values = query_data.map do |datum|
        Series::Value.new(
          date: datum.date,
          date_formatted: I18n.l(datum.date, format: :long),
          value: Money.new(datum.send(column), currency),
          trend: Trend.new(
            current: Money.new(datum.send(column), currency),
            previous: Money.new(datum.send("previous_#{column}"), currency),
            favorable_direction: favorable_direction
          )
        )
      end

      Series.new(
        start_date: period.start_date,
        end_date: period.end_date,
        interval: interval,
        values: values,
        favorable_direction: favorable_direction
      )
    end

    def query_data
      @query_data ||= Balance.find_by_sql([
        query,
        {
          account_ids: account_ids,
          target_currency: currency,
          start_date: period.start_date,
          end_date: period.end_date,
          interval: interval,
          sign_multiplier: sign_multiplier
        }
      ])
    rescue => e
      Rails.logger.error "Query data error: #{e.message} for accounts #{account_ids}, period #{period.start_date} to #{period.end_date}"
      raise
    end

    # Since the query aggregates the *net* of assets - liabilities, this means that if we're looking at
    # a single liability account, we'll get a negative set of values.  This is not what the user expects
    # to see.  When favorable direction is "down" (i.e. liability, decrease is "good"), we need to invert
    # the values by multiplying by -1.
    def sign_multiplier
      favorable_direction == "down" ? -1 : 1
    end

    def query
      <<~SQL
        WITH dates AS (
          SELECT generate_series(DATE :start_date, DATE :end_date, :interval::interval)::date AS date
          UNION DISTINCT
          SELECT :end_date::date  -- Pass in date to ensure timezone-aware "today" date
        ), aggregated_balances AS (
          SELECT
            d.date,
            -- Total balance (assets positive, liabilities negative)
            SUM(
              CASE WHEN accounts.classification = 'asset'
                THEN COALESCE(last_bal.balance, 0)
                ELSE -COALESCE(last_bal.balance, 0)
              END * COALESCE(er.rate, 1) * :sign_multiplier::integer
            ) AS balance,
            -- Cash-only balance
            SUM(
              CASE WHEN accounts.classification = 'asset'
                THEN COALESCE(last_bal.cash_balance, 0)
                ELSE -COALESCE(last_bal.cash_balance, 0)
              END * COALESCE(er.rate, 1) * :sign_multiplier::integer
            ) AS cash_balance,
            -- Holdings value (balance ‑ cash)
            SUM(
              CASE WHEN accounts.classification = 'asset'
                THEN COALESCE(last_bal.balance, 0) - COALESCE(last_bal.cash_balance, 0)
                ELSE 0
              END * COALESCE(er.rate, 1) * :sign_multiplier::integer
            ) AS holdings_balance
          FROM dates d
          JOIN accounts ON accounts.id = ANY(array[:account_ids]::uuid[])

          -- Last observation carried forward (LOCF), use the most recent balance on or before the chart date
          LEFT JOIN LATERAL (
            SELECT b.balance, b.cash_balance
            FROM balances b
            WHERE b.account_id = accounts.id
              AND b.date <= d.date
            ORDER BY b.date DESC
            LIMIT 1
          ) last_bal ON TRUE

          -- Last observation carried forward (LOCF), use the most recent exchange rate on or before the chart date
          LEFT JOIN LATERAL (
            SELECT er.rate
            FROM exchange_rates er
            WHERE er.from_currency = accounts.currency
              AND er.to_currency = :target_currency
              AND er.date <= d.date
            ORDER BY er.date DESC
            LIMIT 1
          ) er ON TRUE
          GROUP BY d.date
        )
        SELECT
          date,
          balance,
          cash_balance,
          holdings_balance,
          COALESCE(LAG(balance) OVER (ORDER BY date), 0) AS previous_balance,
          COALESCE(LAG(cash_balance) OVER (ORDER BY date), 0) AS previous_cash_balance,
          COALESCE(LAG(holdings_balance) OVER (ORDER BY date), 0) AS previous_holdings_balance
        FROM aggregated_balances
        ORDER BY date
      SQL
    end
end
