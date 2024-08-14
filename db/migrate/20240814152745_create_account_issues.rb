class CreateAccountIssues < ActiveRecord::Migration[7.2]
  def change
    create_table :account_issues, id: :uuid do |t|
      t.references :account, null: false, foreign_key: true, type: :uuid
      t.string :type, null: false
      t.integer :priority
      t.datetime :last_observed_at, default: Time.now
      t.datetime :resolved_at
      t.jsonb :data

      t.timestamps
    end
  end
end
