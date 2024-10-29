class AddReferenceToSecurityPrices < ActiveRecord::Migration[7.2]
  def change
    add_reference :security_prices, :security, foreign_key: true, type: :uuid

    reversible do |dir|
      dir.up do
        Security::Price.find_each do |sp|
          security = Security.find_by(ticker: sp.ticker)
          sp.update_column(:security_id, security&.id)
        end
      end
    end
  end
end
