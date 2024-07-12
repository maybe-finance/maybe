class CreateAccountSyncs < ActiveRecord::Migration[7.2]
  def change
    create_table :account_syncs, id: :uuid do |t|
      t.references :account, null: false, foreign_key: true, type: :uuid
      t.string :status, null: false, default: "pending"
      t.date :start_date
      t.datetime :last_ran_at
      t.string :error
      t.text :warnings, array: true, default: []

      t.timestamps
    end

    remove_column :accounts, :status, :string
    remove_column :accounts, :sync_warnings, :jsonb
    remove_column :accounts, :sync_errors, :jsonb
  end
end
