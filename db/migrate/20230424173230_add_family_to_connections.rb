class AddFamilyToConnections < ActiveRecord::Migration[7.1]
  def change
    # Add reference to family, uuid
    add_reference :connections, :family, foreign_key: true, type: :uuid

    # Migrate existing connections to family
    User.all.each do |user|
      family = user.family

      user.connections.update_all(family_id: family.id)
    end
  end
end
