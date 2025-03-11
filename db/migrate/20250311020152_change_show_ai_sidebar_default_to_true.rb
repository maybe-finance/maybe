class ChangeShowAiSidebarDefaultToTrue < ActiveRecord::Migration[7.2]
  def change
    change_column_default :users, :show_ai_sidebar, from: false, to: true
  end
end
