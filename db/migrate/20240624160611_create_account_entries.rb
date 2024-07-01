class CreateAccountEntries < ActiveRecord::Migration[7.2]
  def change
    create_table :account_entries, id: :uuid do |t|
      t.references :account, null: false, foreign_key: true, type: :uuid
      t.string :entryable_type
      t.uuid :entryable_id
      t.decimal :amount, precision: 19, scale: 4
      t.string :currency
      t.date :date
      t.string :name

      t.timestamps
    end
  end
end
