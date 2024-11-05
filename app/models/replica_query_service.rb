class ReplicaQueryService
  class ReplicaConnection < ActiveRecord::Base
    self.abstract_class = true
  end

  def self.execute(query:, family_id:)
    ReplicaConnection.establish_connection(ENV["READONLY_DATABASE_URL"])

    scoped_query = "
      WITH metrics AS (
        SELECT date, account_id, family_id, kind, value
        FROM metrics
        WHERE family_id = '#{family_id}'
        UNION ALL
        SELECT date, account_id, '#{family_id}' as family_id, 'balance_metric' as kind, balance as value
        FROM account_balances
        WHERE account_id IN (SELECT id FROM accounts WHERE family_id = '#{family_id}')
        UNION ALL
        SELECT date, account_id, '#{family_id}' as family_id, 'holding_metric' as kind, amount as value
        FROM account_holdings
        WHERE account_id IN (SELECT id FROM accounts WHERE family_id = '#{family_id}')
      )
      #{query}
    "

    result = ReplicaConnection.connection.execute(scoped_query)

    # Close the connection when done
    ReplicaConnection.connection_pool.disconnect!

    result
  end
end
