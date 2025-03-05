class AddSignageTypeToImports < ActiveRecord::Migration[7.2]
  def change
    change_column_default :imports, :date_col_label, from: "date", to: nil
    change_column_default :imports, :amount_col_label, from: "amount", to: nil
    change_column_default :imports, :name_col_label, from: "name", to: nil
    change_column_default :imports, :category_col_label, from: "category", to: nil
    change_column_default :imports, :tags_col_label, from: "tags", to: nil
    change_column_default :imports, :account_col_label, from: "account", to: nil
    change_column_default :imports, :qty_col_label, from: "qty", to: nil
    change_column_default :imports, :ticker_col_label, from: "ticker", to: nil
    change_column_default :imports, :price_col_label, from: "price", to: nil
    change_column_default :imports, :entity_type_col_label, from: "entity_type", to: nil
    change_column_default :imports, :notes_col_label, from: "notes", to: nil
    change_column_default :imports, :currency_col_label, from: "currency", to: nil

    # User can select "custom", then assign "debit" or "credit" (or custom value) to determine inflow/outflow of txn
    add_column :imports, :amount_type_strategy, :string, default: "signed_amount"
    add_column :imports, :amount_type_inflow_value, :string
  end
end
