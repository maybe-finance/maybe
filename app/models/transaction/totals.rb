class Transaction::Totals
  # Service for computing transaction totals with multi-currency support
  # Uses kind filtering to exclude transfers/payments but include loan_payment as expenses
  def self.compute(search)
    new(search).call
  end

  def initialize(search)
    @search = search
  end

  def call
    result = execute_query.first

    ScopeTotals.new(
      transactions_count: result["transactions_count"].to_i,
      income_money: Money.new(result["income_total"].to_i, result["currency"]),
      expense_money: Money.new(result["expense_total"].to_i, result["currency"])
    )
  end

  private
    ScopeTotals = Data.define(:transactions_count, :income_money, :expense_money)

    def execute_query
      ActiveRecord::Base.connection.select_all(sanitized_query)
    end

    def sanitized_query
      ActiveRecord::Base.sanitize_sql_array([ query_sql, { target_currency: @search.family.currency } ])
    end

    def query_sql
      <<~SQL
        SELECT
          COALESCE(SUM(CASE WHEN ae.amount >= 0 THEN ABS(ae.amount * COALESCE(er.rate, 1)) * 100 ELSE 0 END), 0) as expense_total,
          COALESCE(SUM(CASE WHEN ae.amount < 0 THEN ABS(ae.amount * COALESCE(er.rate, 1)) * 100 ELSE 0 END), 0) as income_total,
          COUNT(ae.id) as transactions_count,
          :target_currency as currency
        FROM (#{transactions_scope.to_sql}) t
        JOIN entries ae ON ae.entryable_id = t.id AND ae.entryable_type = 'Transaction'
        LEFT JOIN exchange_rates er ON (
          er.date = ae.date AND
          er.from_currency = ae.currency AND
          er.to_currency = :target_currency
        )
        WHERE t.kind NOT IN ('transfer', 'one_time', 'payment');
      SQL
    end

    def transactions_scope
      @search.relation
    end
end
