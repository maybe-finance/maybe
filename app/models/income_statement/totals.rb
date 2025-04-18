class IncomeStatement::Totals
  include IncomeStatement::BaseQuery

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
      base_sql = base_query_sql(family: @family, interval: "day", transactions_scope: @transactions_scope)

      <<~SQL
        WITH base_totals AS (
          #{base_sql}
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
end
