class RemoveMerchantManagement < ActiveRecord::Migration[7.2]
  # This migration removes "manual management" of merchants and moves us to 100% automated
  # detection of merchants based on transaction name (using Synth + AI).
  # -----
  # Once we're confident in changes, we'll come back and remove all "legacy" schemas.
  def change
    rename_table :merchants, :legacy_merchants
    rename_column :account_transactions, :merchant_id, :legacy_merchant_id

    create_table :merchants, id: :uuid do |t|
      t.string :name, null: false, index: { unique: true }
      t.string :website_url
      t.string :icon_url
      t.timestamps
    end

    add_reference :account_transactions, :merchant, type: :uuid, foreign_key: true

    # Users will now opt-in with "rules", so reset enriched names (original name retained)
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE account_entries
          SET enriched_name = NULL
        SQL
      end
    end
  end
end
