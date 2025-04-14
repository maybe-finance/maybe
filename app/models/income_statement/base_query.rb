module IncomeStatement::BaseQuery
  private
    def base_query_sql(family:, interval:, transactions_scope:)
      sql = <<~SQL
        SELECT
          c.id as category_id,
          c.parent_id as parent_category_id,
          date_trunc(:interval, ae.date) as date,
          CASE WHEN ae.amount < 0 THEN 'income' ELSE 'expense' END as classification,
          SUM(ae.amount * COALESCE(er.rate, 1)) as total,
          COUNT(ae.id) as transactions_count,
          BOOL_OR(ae.currency <> :target_currency AND er.rate IS NULL) as missing_exchange_rates
        FROM (#{transactions_scope.to_sql}) at
        JOIN entries ae ON ae.entryable_id = at.id AND ae.entryable_type = 'Transaction'
        LEFT JOIN categories c ON c.id = at.category_id
        LEFT JOIN (
          SELECT t.*, t.id as transfer_id, a.accountable_type
          FROM transfers t
          JOIN entries ae ON ae.entryable_id = t.inflow_transaction_id
            AND ae.entryable_type = 'Transaction'
          JOIN accounts a ON a.id = ae.account_id
        ) transfer_info ON (
          transfer_info.inflow_transaction_id = at.id OR
          transfer_info.outflow_transaction_id = at.id
        )
        LEFT JOIN exchange_rates er ON (
          er.date = ae.date AND
          er.from_currency = ae.currency AND
          er.to_currency = :target_currency
        )
        WHERE (
          transfer_info.transfer_id IS NULL OR
          (ae.amount > 0 AND transfer_info.accountable_type = 'Loan')
        )
        GROUP BY 1, 2, 3, 4
      SQL

      ActiveRecord::Base.sanitize_sql_array([
        sql,
        { target_currency: family.currency, interval: interval }
      ])
    end
end
