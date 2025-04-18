class MerchantAndCategoryEnrichment < ActiveRecord::Migration[7.2]
  def change
    change_column_null :merchants, :family_id, true
    change_column_null :merchants, :color, true
    change_column_default :merchants, :color, from: "#e99537", to: nil
    remove_column :merchants, :enriched_at, :datetime
    rename_column :merchants, :icon_url, :logo_url

    add_column :merchants, :website_url, :string
    add_column :merchants, :type, :string
    add_index :merchants, :type

    reversible do |dir|
      dir.up do
        ActiveRecord::Base.transaction do
          # 1) Mark all existing as FamilyMerchant
          Merchant.update_all(type: "FamilyMerchant")

          # 2) Find duplicate family merchants
          Merchant
            .where(type: 'FamilyMerchant')
            .group(:family_id, :name)
            .having("COUNT(*) > 1")
            .pluck(:family_id, :name)
            .each do |family_id, name|
            # 3) Grab sorted IDs, first is keeper
            ids, duplicate_ids = Merchant
              .where(family_id: family_id, name: name)
              .order(:id)
              .pluck(:id)
              .then { |arr| [ arr.first, arr.drop(1) ] }

            next if duplicate_ids.empty?

            # 4) Reassign all transactions pointing at the duplicates
            Transaction.where(merchant_id: duplicate_ids)
                       .update_all(merchant_id: ids)

            # 5) Delete the duplicate merchant rows
            Merchant.where(id: duplicate_ids).delete_all
          end
        end
      end
    end

    change_column_null :merchants, :type, false

    add_column :merchants, :source, :string
    add_column :merchants, :provider_merchant_id, :string

    add_index :merchants, [ :family_id, :name ], unique: true, where: "type = 'FamilyMerchant'"
    add_index :merchants, [ :source, :name ], unique: true, where: "type = 'ProviderMerchant'"

    add_column :transactions, :plaid_category, :string
    add_column :transactions, :plaid_category_detailed, :string

    remove_column :entries, :enriched_name, :string
    remove_column :entries, :enriched_at, :datetime
  end
end
