class UserRuleNotifications < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :rule_prompts_disabled, :boolean, default: false
    add_column :users, :rule_prompt_dismissed_at, :datetime
  end
end
