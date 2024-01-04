class AddSubkindToMetrics < ActiveRecord::Migration[7.1]
  def change
    # Add subkind to metrics
    add_column :metrics, :subkind, :string
  end
end
