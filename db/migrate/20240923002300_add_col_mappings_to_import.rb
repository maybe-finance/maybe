class AddColMappingsToImport < ActiveRecord::Migration[7.2]
  def change
    change_table :imports do |t|
      t.string :date_col_label
      t.string :amount_col_label
      t.string :name_col_label
      t.string :category_col_label
      t.string :tags_col_label
      t.string :account_col_label
      t.string :qty_col_label
      t.string :price_col_label
      t.string :type_col_label

      t.string :date_format, default: "YYYY-MM-DD"
      t.string :amount_sign_format, default: "incomes_are_negative"
    end
  end
end
