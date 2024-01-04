class CreateSecurities < ActiveRecord::Migration[7.1]
  def change
    create_table :securities, id: :uuid do |t|
      t.string :name
      t.string :symbol
      t.string :cusip
      t.string :isin
      t.string :currency_code
      t.string :source, null: false
      t.string :source_id
      t.string :source_type
      t.decimal :shares_per_contract, precision: 36, scale: 19
      t.boolean :is_cash_equivalent, default: false

      t.timestamps
    end

    add_index :securities, :source_id, unique: true
    add_index :securities, [:source, :source_id], unique: true
  end
end
