class AddGinIndexToTransactionCategoriesName < ActiveRecord::Migration[7.2]
  def change
    enable_extension 'pg_trgm' unless extension_enabled?('pg_trgm')
    add_index :transaction_categories, "name gin_trgm_ops", using: :gin, name: "index_transaction_categories_on_name_gin"
  end
end
