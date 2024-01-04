class AddFamilyToAccounts < ActiveRecord::Migration[7.1]
  def change
    # Add reference to family, uuid
    add_reference :accounts, :family, foreign_key: true, type: :uuid

    # Migrate existing accounts to family
    User.all.each do |user|
      family = user.family

      user.accounts.update_all(family_id: family.id)
    end
  end
end
