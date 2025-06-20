class IncomeStatement::CategoryStats
  def initialize(family, interval: "month")
    @family = family
    @interval = interval
  end

  def call
    ActiveRecord::Base.connection.select_all(sanitized_query_sql).map do |row|
      StatRow.new(
        category_id: row["category_id"],
        classification: row["classification"],
        median: row["median"],
        avg: row["avg"]
      )
    end
  end

  private
    StatRow = Data.define(:category_id, :classification, :median, :avg)

    def sanitized_query_sql
      ActiveRecord::Base.sanitize_sql_array([
        query_sql,
        {
          target_currency: @family.currency,
          interval: @interval,
          family_id: @family.id
        }
      ])
    end

    def query_sql
      <<~SQL
        WITH period_totals AS (
          SELECT
            c.id as category_id,
            date_trunc(:interval, ae.date) as period,
            CASE WHEN ae.amount < 0 THEN 'income' ELSE 'expense' END as classification,
            SUM(ae.amount * COALESCE(er.rate, 1)) as total
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
            AND t.kind NOT IN ('funds_movement', 'one_time', 'cc_payment')
            AND ae.excluded = false
          GROUP BY c.id, period, CASE WHEN ae.amount < 0 THEN 'income' ELSE 'expense' END
        )
        SELECT
          category_id,
          classification,
          ABS(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total)) as median,
          ABS(AVG(total)) as avg
        FROM period_totals
        GROUP BY category_id, classification;
      SQL
    end
end
