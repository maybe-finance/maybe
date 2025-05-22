class AddSecurityResolverFields < ActiveRecord::Migration[7.2]
  def change
    add_column :securities, :offline, :boolean, default: false, null: false
    add_column :securities, :failed_fetch_at, :datetime
    add_column :securities, :failed_fetch_count, :integer, default: 0, null: false
    add_column :securities, :last_health_check_at, :datetime
  end
end
