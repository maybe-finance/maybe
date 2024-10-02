class AddImportTypes < ActiveRecord::Migration[7.2]
  def change
    change_table :imports do |t|
      t.string :type
      t.string :date_col_label, default: "date"
      t.string :amount_col_label, default: "amount"
      t.string :name_col_label, default: "name"
      t.string :category_col_label, default: "category"
      t.string :tags_col_label, default: "tags"
      t.string :account_col_label, default: "account"
      t.string :qty_col_label, default: "qty"
      t.string :ticker_col_label, default: "ticker"
      t.string :price_col_label, default: "price"
      t.string :entity_type_col_label, default: "type"
      t.string :notes_col_label, default: "notes"
      t.string :currency_col_label, default: "currency"
      t.string :date_format, default: "%m/%d/%Y"
      t.string :signage_convention, default: "inflows_positive"
      t.string :error
    end

    Import.update_all(type: "TransactionImport")

    change_column_null :imports, :type, false

    # Add import references so we can associate imported resources after the import
    add_reference :account_entries, :import, foreign_key: true, type: :uuid
    add_reference :accounts, :import, foreign_key: true, type: :uuid

    create_table :import_rows, id: :uuid do |t|
      t.references :import, null: false, foreign_key: true, type: :uuid
      t.string :account
      t.string :date
      t.string :qty
      t.string :ticker
      t.string :price
      t.string :amount
      t.string :currency
      t.string :name
      t.string :category
      t.string :tags
      t.string :entity_type
      t.text :notes

      t.timestamps
    end

    create_table :import_mappings, id: :uuid do |t|
      t.string :type, null: false
      t.string :key
      t.string :value
      t.boolean :create_when_empty, default: true
      t.references :import, null: false, type: :uuid
      t.references :mappable, polymorphic: true, type: :uuid

      t.timestamps
    end
  end
end
