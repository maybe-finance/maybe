class IncomeStatement::Totals
  def initialize(family, transactions_scope:)
    @family = family
    @transactions_scope = transactions_scope
  end

  def call
    ActiveRecord::Base.connection.select_all(query_sql).map do |row|
      TotalsRow.new(
        parent_category_id: row["parent_category_id"],
        category_id: row["category_id"],
        classification: row["classification"],
        total: row["total"],
        transactions_count: row["transactions_count"],
        missing_exchange_rates?: row["missing_exchange_rates"]
      )
    end
  end

  private
    TotalsRow = Data.define(:parent_category_id, :category_id, :classification, :total, :transactions_count, :missing_exchange_rates?)

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
          FROM (#{@transactions_scope.to_sql}) at
          JOIN entries ae ON ae.entryable_id = at.id AND ae.entryable_type = 'Transaction'
          LEFT JOIN categories c ON c.id = at.category_id
          LEFT JOIN exchange_rates er ON (
            er.date = ae.date AND
            er.from_currency = ae.currency AND
            er.to_currency = :target_currency
          )
          WHERE at.kind NOT IN ('transfer', 'one_time', 'payment')
          GROUP BY 1, 2, 3, 4
        )
        SELECT
            parent_category_id,
            category_id,
            classification,
            ABS(SUM(total)) as total,
            BOOL_OR(missing_exchange_rates) as missing_exchange_rates,
            SUM(transactions_count) as transactions_count
        FROM base_totals
        GROUP BY 1, 2, 3;
      SQL
    end

    def sql_params
      {
        target_currency: @family.currency,
        interval: "day" # Totals always uses day interval
      }
    end
end
