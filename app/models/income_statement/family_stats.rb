class IncomeStatement::FamilyStats
  def initialize(family, interval: "month")
    @family = family
    @interval = interval
  end

  def call
    ActiveRecord::Base.connection.select_all(query_sql).map do |row|
      StatRow.new(
        classification: row["classification"],
        median: row["median"],
        avg: row["avg"]
      )
    end
  end

  private
    StatRow = Data.define(:classification, :median, :avg)

    def query_sql
      ActiveRecord::Base.sanitize_sql_array([
        optimized_query_sql,
        sql_params
      ])
    end

    # OPTIMIZED: Use interval for time bucketing but eliminate double CTE
    # Single CTE instead of base_totals -> aggregated_totals -> final aggregation
    def optimized_query_sql
      <<~SQL
        WITH period_totals AS (
          SELECT
            date_trunc(:interval, ae.date) as period,
            CASE WHEN ae.amount < 0 THEN 'income' ELSE 'expense' END as classification,
            SUM(ae.amount * COALESCE(er.rate, 1)) as total
          FROM transactions t
          JOIN entries ae ON ae.entryable_id = t.id AND ae.entryable_type = 'Transaction'
          JOIN accounts a ON a.id = ae.account_id
          LEFT JOIN exchange_rates er ON (
            er.date = ae.date AND
            er.from_currency = ae.currency AND
            er.to_currency = :target_currency
          )
          WHERE a.family_id = :family_id
            AND t.kind NOT IN ('transfer', 'one_time', 'payment')
          GROUP BY period, CASE WHEN ae.amount < 0 THEN 'income' ELSE 'expense' END
        )
        SELECT
          classification,
          ABS(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total)) as median,
          ABS(AVG(total)) as avg
        FROM period_totals
        GROUP BY classification;
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
