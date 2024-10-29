class AddReferenceToSecurityPrices < ActiveRecord::Migration[7.2]
  def change
    add_reference :security_prices, :security, foreign_key: true, type: :uuid
  end
end
