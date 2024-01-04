class AddFamilyToHoldings < ActiveRecord::Migration[7.1]
  def change
    # Add reference to family, uuid
    add_reference :holdings, :family, foreign_key: true, type: :uuid

    # Migrate existing holdings to family
    Account.all.each do |account|
      family = account.family

      account.holdings.update_all(family_id: family.id)
    end
  end
end
