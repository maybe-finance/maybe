class AddStartEndColumnsToBalances < ActiveRecord::Migration[7.2]
  def up
    # Rename existing columns to deprecated versions
    # rename_column :balances, :balance, :balance_deprecated
    # rename_column :balances, :cash_balance, :cash_balance_deprecated

    # Add new columns for balance tracking
    add_column :balances, :start_cash_balance, :decimal, precision: 19, scale: 4, null: false, default: 0.0
    add_column :balances, :start_non_cash_balance, :decimal, precision: 19, scale: 4, null: false, default: 0.0

    # Flow tracking columns (absolute values)
    add_column :balances, :cash_inflows, :decimal, precision: 19, scale: 4, null: false, default: 0.0
    add_column :balances, :cash_outflows, :decimal, precision: 19, scale: 4, null: false, default: 0.0
    add_column :balances, :non_cash_inflows, :decimal, precision: 19, scale: 4, null: false, default: 0.0
    add_column :balances, :non_cash_outflows, :decimal, precision: 19, scale: 4, null: false, default: 0.0

    # Market value changes
    add_column :balances, :net_market_flows, :decimal, precision: 19, scale: 4, null: false, default: 0.0

    # Manual adjustments from valuations
    add_column :balances, :cash_adjustments, :decimal, precision: 19, scale: 4, null: false, default: 0.0
    add_column :balances, :non_cash_adjustments, :decimal, precision: 19, scale: 4, null: false, default: 0.0

    # Add generated columns
    change_table :balances do |t|
      t.virtual :start_balance, type: :decimal, precision: 19, scale: 4, stored: true,
        as: "start_cash_balance + start_non_cash_balance"

      t.virtual :end_cash_balance, type: :decimal, precision: 19, scale: 4, stored: true,
        as: "start_cash_balance + cash_inflows - cash_outflows + cash_adjustments"

      t.virtual :end_non_cash_balance, type: :decimal, precision: 19, scale: 4, stored: true,
        as: "start_non_cash_balance + non_cash_inflows - non_cash_outflows + net_market_flows + non_cash_adjustments"

      # Postgres doesn't support generated columns depending on other generated columns,
      # but we want the integrity of the data to happen at the DB level, so this is the full formula.
      # Formula: (cash components) + (non-cash components)
      t.virtual :end_balance, type: :decimal, precision: 19, scale: 4, stored: true,
        as: <<~SQL.squish
          (
            start_cash_balance +
            cash_inflows -
            cash_outflows +
            cash_adjustments
          ) + (
            start_non_cash_balance +
            non_cash_inflows -
            non_cash_outflows +
            net_market_flows +
            non_cash_adjustments
          )
        SQL
    end

    # Migrate existing data

    # Step 1: Set start values using LOCF (Last Observation Carried Forward)
    execute <<~SQL
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

    # Step 2: Calculate net flows as inflows (can be negative)
    # We use net change as inflows, outflows stay 0 for historical data
    execute <<~SQL
      UPDATE balances SET
        cash_inflows = cash_balance - start_cash_balance,
        cash_outflows = 0,
        non_cash_inflows = (balance - cash_balance) - start_non_cash_balance,
        non_cash_outflows = 0,
        net_market_flows = 0
    SQL

    # Step 3: Initialize adjustments to 0
    execute <<~SQL
      UPDATE balances SET
        cash_adjustments = 0,
        non_cash_adjustments = 0
    SQL

    # Step 4: Calculate adjustments from valuation entries
    execute <<~SQL
      WITH valuation_data AS (
        SELECT#{' '}
          e.account_id,
          e.date,
          e.amount as valuation_amount,
          e.currency,
          a.accountable_type
        FROM entries e
        JOIN accounts a ON a.id = e.account_id
        WHERE e.entryable_type = 'Valuation'
      )
      UPDATE balances b
      SET
        cash_adjustments = CASE
          -- For investment accounts: valuation sets total, preserve holdings value
          WHEN vd.accountable_type = 'Investment' THEN
            vd.valuation_amount - (b.start_balance + b.cash_inflows + b.non_cash_inflows)
          -- For loan accounts: adjustment goes to non-cash
          WHEN vd.accountable_type = 'Loan' THEN
            0
          -- For all other accounts: adjustment goes to cash
          ELSE
            vd.valuation_amount - (b.start_balance + b.cash_inflows + b.non_cash_inflows)
        END,
        non_cash_adjustments = CASE
          -- Only loan accounts get non-cash adjustments
          WHEN vd.accountable_type = 'Loan' THEN
            vd.valuation_amount - (b.start_balance + b.cash_inflows + b.non_cash_inflows)
        ELSE
          0
        END
      FROM valuation_data vd
      WHERE b.account_id = vd.account_id
      AND b.date = vd.date
      AND b.currency = vd.currency
    SQL
  end

  def down
    # Remove generated columns first (PostgreSQL requirement)
    remove_column :balances, :start_balance
    remove_column :balances, :end_cash_balance
    remove_column :balances, :end_non_cash_balance
    remove_column :balances, :end_balance

    # Remove new columns
    remove_column :balances, :start_cash_balance
    remove_column :balances, :start_non_cash_balance
    remove_column :balances, :cash_inflows
    remove_column :balances, :cash_outflows
    remove_column :balances, :non_cash_inflows
    remove_column :balances, :non_cash_outflows
    remove_column :balances, :net_market_flows
    remove_column :balances, :cash_adjustments
    remove_column :balances, :non_cash_adjustments

    # Restore original column names
    # rename_column :balances, :balance_deprecated, :balance
    # rename_column :balances, :cash_balance_deprecated, :cash_balance
  end
end
