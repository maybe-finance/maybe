class RemoveIssues < ActiveRecord::Migration[7.2]
  def change
    drop_table :issues do |t|
      t.references :issuable, polymorphic: true, null: false
      t.string :type, null: false
      t.integer :severity, null: false
      t.datetime :last_observed_at
      t.datetime :resolved_at
    end
  end
end
