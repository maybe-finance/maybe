class CreateAccounts < ActiveRecord::Migration[7.1]
  def change
    create_table :accounts, id: :uuid do |t|
      t.string :name
      t.string :source_id
      t.boolean :is_active, default: true
      t.string :type
      t.string :subtype
      t.references :connection, null: false, foreign_key: true, type: :uuid
      t.decimal :available_balance, precision: 19, scale: 4
      t.decimal :current_balance, precision: 19, scale: 4
      t.string :currency_code
      t.integer :sync_status, default: 0
      t.string :mask
      t.integer :source
      t.date :current_balance_date

      t.timestamps
    end
  end
end
