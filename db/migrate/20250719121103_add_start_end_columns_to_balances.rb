class AddStartEndColumnsToBalances < ActiveRecord::Migration[7.2]
  def up
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

    # Flows factor determines *how* the flows affect the balance.
    # Inflows increase asset accounts, while inflows decrease liability accounts (reducing debt via "payment")
    add_column :balances, :flows_factor, :integer, null: false, default: 1

    # Add generated columns
    change_table :balances do |t|
      t.virtual :start_balance, type: :decimal, precision: 19, scale: 4, stored: true,
        as: "start_cash_balance + start_non_cash_balance"

      t.virtual :end_cash_balance, type: :decimal, precision: 19, scale: 4, stored: true,
        as: "start_cash_balance + ((cash_inflows - cash_outflows) * flows_factor) + cash_adjustments"

      t.virtual :end_non_cash_balance, type: :decimal, precision: 19, scale: 4, stored: true,
        as: "start_non_cash_balance + ((non_cash_inflows - non_cash_outflows) * flows_factor) + net_market_flows + non_cash_adjustments"

      # Postgres doesn't support generated columns depending on other generated columns,
      # but we want the integrity of the data to happen at the DB level, so this is the full formula.
      # Formula: (cash components) + (non-cash components)
      t.virtual :end_balance, type: :decimal, precision: 19, scale: 4, stored: true,
        as: <<~SQL.squish
          (
            start_cash_balance +
            ((cash_inflows - cash_outflows) * flows_factor) +
            cash_adjustments
          ) + (
            start_non_cash_balance +
            ((non_cash_inflows - non_cash_outflows) * flows_factor) +
            net_market_flows +
            non_cash_adjustments
          )
        SQL
    end
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
  end
end
