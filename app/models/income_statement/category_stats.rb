class IncomeStatement::CategoryStats
  def initialize(family, interval: "month")
    @family = family
    @interval = interval
  end

  def call
    ActiveRecord::Base.connection.select_all(query_sql).map do |row|
      StatRow.new(
        category_id: row["category_id"],
        classification: row["classification"],
        median: row["median"],
        avg: row["avg"],
        missing_exchange_rates?: row["missing_exchange_rates"]
      )
    end
  end

  private
    StatRow = Data.define(:category_id, :classification, :median, :avg, :missing_exchange_rates?)

    def query_sql
      ActiveRecord::Base.sanitize_sql_array([
        optimized_query_sql,
        sql_params
      ])
    end

    # OPTIMIZED: Use interval for time bucketing but eliminate unnecessary intermediate CTE
    # Still faster than original due to simplified structure and kind filtering
    def optimized_query_sql
      <<~SQL
        WITH period_totals AS (
          SELECT
            c.id as category_id,
            date_trunc(:interval, ae.date) as period,
            CASE WHEN ae.amount < 0 THEN 'income' ELSE 'expense' END as classification,
            SUM(ae.amount * COALESCE(er.rate, 1)) as total,
            BOOL_OR(ae.currency <> :target_currency AND er.rate IS NULL) as missing_exchange_rates
          FROM transactions t
          JOIN entries ae ON ae.entryable_id = t.id AND ae.entryable_type = 'Transaction'
          JOIN accounts a ON a.id = ae.account_id
          LEFT JOIN categories c ON c.id = t.category_id
          LEFT JOIN exchange_rates er ON (
            er.date = ae.date AND
            er.from_currency = ae.currency AND
            er.to_currency = :target_currency
          )
          WHERE a.family_id = :family_id
            AND t.kind NOT IN ('transfer', 'one_time', 'payment')
          GROUP BY c.id, period, CASE WHEN ae.amount < 0 THEN 'income' ELSE 'expense' END
        )
        SELECT
          category_id,
          classification,
          ABS(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total)) as median,
          ABS(AVG(total)) as avg,
          BOOL_OR(missing_exchange_rates) as missing_exchange_rates
        FROM period_totals
        GROUP BY category_id, classification;
      SQL
    end

    def sql_params
      {
        target_currency: @family.currency,
        interval: @interval,
        family_id: @family.id
      }
    end
end
