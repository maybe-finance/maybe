class AddUniqIndexOnMetrics < ActiveRecord::Migration[7.1]
  def change
    # Find duplicate metrics
    duplicate_metrics = Metric.group(:kind, :user_id, :date).having("count(*) > 1").count

    # Remove duplicate metrics
    duplicate_metrics.each do |(kind, user_id, date), count|
      Metric.where(kind: kind, user_id: user_id, date: date).order(created_at: :desc).offset(1).destroy_all
    end

    # This index is needed to avoid duplicate metrics
    add_index :metrics, [:kind, :user_id, :date], unique: true
  end
end
