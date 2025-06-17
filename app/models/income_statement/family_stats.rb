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
        avg: row["avg"],
        missing_exchange_rates?: row["missing_exchange_rates"]
      )
    end
  end

  private
    StatRow = Data.define(:classification, :median, :avg, :missing_exchange_rates?)

    def query_sql
      ActiveRecord::Base.sanitize_sql_array([
        base_query_sql,
        sql_params
      ])
    end

    def base_query_sql
      <<~SQL
        WITH base_totals AS (
          SELECT
            c.id as category_id,
            c.parent_id as parent_category_id,
            date_trunc(:interval, ae.date) as date,
            CASE WHEN ae.amount < 0 THEN 'income' ELSE 'expense' END as classification,
            SUM(ae.amount * COALESCE(er.rate, 1)) as total,
            COUNT(ae.id) as transactions_count,
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
          GROUP BY 1, 2, 3, 4
        ), aggregated_totals AS (
          SELECT
            date,
            classification,
            SUM(total) as total,
            BOOL_OR(missing_exchange_rates) as missing_exchange_rates
          FROM base_totals
          GROUP BY date, classification
        )
        SELECT
            classification,
            ABS(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total)) as median,
            ABS(AVG(total)) as avg,
            BOOL_OR(missing_exchange_rates) as missing_exchange_rates
        FROM aggregated_totals
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
