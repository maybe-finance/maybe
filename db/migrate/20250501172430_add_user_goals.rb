class AddUserGoals < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :goals, :text, array: true, default: []
    add_column :users, :set_onboarding_preferences_at, :datetime
    add_column :users, :set_onboarding_goals_at, :datetime

    add_column :families, :trial_started_at, :datetime
    add_column :families, :early_access, :boolean, default: false

    reversible do |dir|
      # All existing families are marked as early access now that we're out of alpha
      dir.up do
        Family.update_all(early_access: true)
      end
    end
  end
end
