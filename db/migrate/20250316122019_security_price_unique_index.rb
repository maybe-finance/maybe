class SecurityPriceUniqueIndex < ActiveRecord::Migration[7.2]
  def change
    # First, we have to delete duplicate prices from DB so we can apply the unique index
    reversible do |dir|
      dir.up do
        execute <<~SQL
          DELETE FROM security_prices
          WHERE id IN (
            SELECT id FROM (
              SELECT id,
              ROW_NUMBER() OVER (
                PARTITION BY security_id, date, currency
                ORDER BY updated_at DESC, id DESC
              ) as row_num
              FROM security_prices
            ) as duplicates
            WHERE row_num > 1
          );
        SQL
      end
    end

    add_index :security_prices, [ :security_id, :date, :currency ], unique: true
    change_column_null :security_prices, :date, false
    change_column_null :security_prices, :price, false
    change_column_null :security_prices, :currency, false

    change_column_null :exchange_rates, :date, false
    change_column_null :exchange_rates, :rate, false
  end
end
