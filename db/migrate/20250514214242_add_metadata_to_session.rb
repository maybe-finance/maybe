class AddMetadataToSession < ActiveRecord::Migration[7.2]
  def change
    add_column :sessions, :data, :jsonb, default: {}
  end
end
