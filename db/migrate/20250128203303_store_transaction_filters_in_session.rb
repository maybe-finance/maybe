class StoreTransactionFiltersInSession < ActiveRecord::Migration[7.2]
  def change
    add_column :sessions, :prev_transaction_page_params, :jsonb, default: {}
  end
end
