class AddConstraintsToAccountHoldings < ActiveRecord::Migration[7.2]
  def up
    # First, remove any holdings with nil values
    execute <<-SQL
      DELETE FROM account_holdings#{' '}
      WHERE date IS NULL#{' '}
         OR qty IS NULL#{' '}
         OR price IS NULL#{' '}
         OR amount IS NULL#{' '}
         OR currency IS NULL;
    SQL

    # Remove any holdings where amount doesn't match qty * price
    execute <<-SQL
      DELETE FROM account_holdings#{' '}
      WHERE ROUND(qty * price, 4) != ROUND(amount, 4);
    SQL

    # Remove any holdings with negative values
    execute <<-SQL
      DELETE FROM account_holdings#{' '}
      WHERE qty < 0 OR price < 0 OR amount < 0;
    SQL

    # Now add NOT NULL constraints
    change_column_null :account_holdings, :date, false
    change_column_null :account_holdings, :qty, false
    change_column_null :account_holdings, :price, false
    change_column_null :account_holdings, :amount, false
    change_column_null :account_holdings, :currency, false

    # Add check constraints
    execute <<-SQL
      ALTER TABLE account_holdings
      ADD CONSTRAINT check_positive_values#{' '}
      CHECK (qty >= 0 AND price >= 0 AND amount >= 0);
    SQL

    execute <<-SQL
      ALTER TABLE account_holdings
      ADD CONSTRAINT check_amount_matches
      CHECK (ROUND(qty * price, 4) = ROUND(amount, 4));
    SQL
  end

  def down
    execute "ALTER TABLE account_holdings DROP CONSTRAINT IF EXISTS check_positive_values;"
    execute "ALTER TABLE account_holdings DROP CONSTRAINT IF EXISTS check_amount_matches;"

    change_column_null :account_holdings, :date, true
    change_column_null :account_holdings, :qty, true
    change_column_null :account_holdings, :price, true
    change_column_null :account_holdings, :amount, true
    change_column_null :account_holdings, :currency, true
  end
end
