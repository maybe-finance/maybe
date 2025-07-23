class BalanceComponentMigrator
  def self.run
    ActiveRecord::Base.transaction do
      # Step 1: Update flows factor
      ActiveRecord::Base.connection.execute <<~SQL
        UPDATE balances SET
          flows_factor = CASE WHEN a.classification = 'asset' THEN 1 ELSE -1 END
        FROM accounts a
        WHERE a.id = balances.account_id
      SQL

      # Step 2: Set start values using LOCF (Last Observation Carried Forward)
      ActiveRecord::Base.connection.execute <<~SQL
        UPDATE balances b1
        SET
          start_cash_balance = COALESCE(prev.cash_balance, 0),
          start_non_cash_balance = COALESCE(prev.balance - prev.cash_balance, 0)
        FROM balances b1_inner
        LEFT JOIN LATERAL (
          SELECT
            b2.cash_balance,
            b2.balance
          FROM balances b2
          WHERE b2.account_id = b1_inner.account_id
          AND b2.currency = b1_inner.currency
          AND b2.date < b1_inner.date
          ORDER BY b2.date DESC
          LIMIT 1
        ) prev ON true
        WHERE b1.id = b1_inner.id
      SQL

      # Step 3: Calculate net inflows
      # A slight workaround to the fact that we can't easily derive inflows/outflows from our current data model, and
      # the tradeoff not worth it since each new sync will fix it. So instead, we sum up *net* flows, and throw the signed
      # amount in the "inflows" column, and zero-out the "outflows" column so our math works correctly with incomplete data.
      ActiveRecord::Base.connection.execute <<~SQL
        UPDATE balances SET
          cash_inflows = (cash_balance - start_cash_balance) * flows_factor,
          cash_outflows = 0,
          non_cash_inflows = ((balance - cash_balance) - start_non_cash_balance) * flows_factor,
          non_cash_outflows = 0,
          net_market_flows = 0
      SQL

      # Verify data integrity
      # All end_balance values should match the original balance
      invalid_count = ActiveRecord::Base.connection.select_value(<<~SQL)
        SELECT COUNT(*)
        FROM balances b
        WHERE ABS(b.balance - b.end_balance) > 0.0001
      SQL

      if invalid_count > 0
        raise "Data migration failed validation: #{invalid_count} balances have incorrect end_balance values"
      end
    end
  end
end
