class ReplicaQueryService
  class ReplicaConnection < ActiveRecord::Base
    self.abstract_class = true
  end

  def self.execute(query:, family_id:)
    ReplicaConnection.establish_connection(ENV["READONLY_DATABASE_URL"])

    # If the query already contains CTEs, we need to merge them with our security CTEs
    if query.strip.upcase.start_with?("WITH")
      # Extract the CTEs and main query
      ctes = query[/WITH\s+(.*?)\s+SELECT/im, 1]
      main_query = query[/SELECT.*$/im]

      scoped_query = <<~SQL
        WITH#{' '}
          -- Core metrics data
          metrics AS (
            SELECT id, date, account_id, family_id, kind, subkind, value
            FROM metrics
            WHERE family_id = '#{family_id}'
            UNION ALL
            SELECT NULL as id, date, account_id, '#{family_id}' as family_id, 'balance_metric' as kind, NULL as subkind, balance as value
            FROM account_balances
            WHERE account_id IN (SELECT id FROM accounts WHERE family_id = '#{family_id}')
            UNION ALL
            SELECT NULL as id, date, account_id, '#{family_id}' as family_id, 'holding_metric' as kind, NULL as subkind, amount as value
            FROM account_holdings
            WHERE account_id IN (SELECT id FROM accounts WHERE family_id = '#{family_id}')
          ),
          -- Security scoped access to core tables
          family_accounts AS (
            SELECT *
            FROM accounts
            WHERE family_id = '#{family_id}'
          ),
          family_entries AS (
            SELECT ae.*
            FROM account_entries ae
            JOIN family_accounts fa ON ae.account_id = fa.id
          ),
          family_categories AS (
            SELECT *
            FROM categories
            WHERE family_id = '#{family_id}'
          ),
          family_merchants AS (
            SELECT *
            FROM merchants
            WHERE family_id = '#{family_id}'
          ),
          family_tags AS (
            SELECT t.*
            FROM tags t
            WHERE family_id = '#{family_id}'
          ),
          #{ctes}
          #{main_query}
      SQL
    else
      scoped_query = <<~SQL
        WITH#{' '}
          -- Core metrics data
          metrics AS (
            SELECT id, date, account_id, family_id, kind, subkind, value
            FROM metrics
            WHERE family_id = '#{family_id}'
            UNION ALL
            SELECT NULL as id, date, account_id, '#{family_id}' as family_id, 'balance_metric' as kind, NULL as subkind, balance as value
            FROM account_balances
            WHERE account_id IN (SELECT id FROM accounts WHERE family_id = '#{family_id}')
            UNION ALL
            SELECT NULL as id, date, account_id, '#{family_id}' as family_id, 'holding_metric' as kind, NULL as subkind, amount as value
            FROM account_holdings
            WHERE account_id IN (SELECT id FROM accounts WHERE family_id = '#{family_id}')
          ),
          -- Security scoped access to core tables
          family_accounts AS (
            SELECT *
            FROM accounts
            WHERE family_id = '#{family_id}'
          ),
          family_entries AS (
            SELECT ae.*
            FROM account_entries ae
            JOIN family_accounts fa ON ae.account_id = fa.id
          ),
          family_categories AS (
            SELECT *
            FROM categories
            WHERE family_id = '#{family_id}'
          ),
          family_merchants AS (
            SELECT *
            FROM merchants
            WHERE family_id = '#{family_id}'
          ),
          family_tags AS (
            SELECT t.*
            FROM tags t
            WHERE family_id = '#{family_id}'
          )
        #{query}
      SQL
    end

    result = ReplicaConnection.connection.execute(scoped_query)

    # Close the connection when done
    ReplicaConnection.connection_pool.disconnect!

    result
  end
end
