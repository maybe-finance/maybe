class AddFamilyToMetrics < ActiveRecord::Migration[7.1]
  def change
    # Add reference to family, uuid
    add_reference :metrics, :family, foreign_key: true, type: :uuid

    # Make user_id nullable and not required
    change_column_null :metrics, :user_id, true

    # Migrate existing metrics to family
    User.all.each do |user|
      family = user.family

      user.metrics.update_all(family_id: family.id)
    end
  end
end
