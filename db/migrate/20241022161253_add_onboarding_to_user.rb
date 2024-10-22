class AddOnboardingToUser < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :onboarded, :boolean, default: false
  end
end
