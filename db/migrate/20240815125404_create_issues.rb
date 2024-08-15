class CreateIssues < ActiveRecord::Migration[7.2]
  def change
    create_table :issues, id: :uuid do |t|
      t.references :issuable, type: :uuid, polymorphic: true
      t.string :code
      t.datetime :last_observed_at
      t.datetime :resolved_at

      t.timestamps
    end
  end
end
