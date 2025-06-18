class Transaction::Totals
  # Service for computing transaction totals with multi-currency support
  def self.compute(search)
    new(search).call
  end

  def initialize(search)
    @search = search
  end

  def call
    ScopeTotals.new(
      transactions_count: query_result["transactions_count"].to_i,
      income_money: Money.new(query_result["income_total"].to_i, query_result["currency"]),
      expense_money: Money.new(query_result["expense_total"].to_i, query_result["currency"])
    )
  end

  private
    ScopeTotals = Data.define(:transactions_count, :income_money, :expense_money)

    def query_result
      ActiveRecord::Base.connection.select_all(sanitized_query).first
    end

    def sanitized_query
      ActiveRecord::Base.sanitize_sql_array([ query_sql, { target_currency: @search.family.currency } ])
    end

    def query_sql
      <<~SQL
        SELECT
          COALESCE(SUM(CASE WHEN ae.amount >= 0 THEN ABS(ae.amount * COALESCE(er.rate, 1)) ELSE 0 END), 0) as expense_total,
          COALESCE(SUM(CASE WHEN ae.amount < 0 THEN ABS(ae.amount * COALESCE(er.rate, 1)) ELSE 0 END), 0) as income_total,
          COUNT(ae.id) as transactions_count,
          :target_currency as currency
        FROM (#{transactions_scope.to_sql}) t
        JOIN entries ae ON ae.entryable_id = t.id AND ae.entryable_type = 'Transaction'
        LEFT JOIN exchange_rates er ON (
          er.date = ae.date AND
          er.from_currency = ae.currency AND
          er.to_currency = :target_currency
        );
      SQL
    end

    def transactions_scope
      @search.relation
    end
end
