class AddUniqueIndexToMetrics < ActiveRecord::Migration[7.2]
  def change
    unless index_exists?(:metrics, [ :family_id, :kind, :date ], name: 'index_metrics_on_family_kind_date_unique')
      add_index :metrics, [ :family_id, :kind, :date ], unique: true, name: 'index_metrics_on_family_kind_date_unique'
    end
  end
end
