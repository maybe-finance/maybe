class CreateConnections < ActiveRecord::Migration[7.1]
  def change
    create_table :connections, id: :uuid do |t|
      t.string :name
      t.integer :source, default: 0
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.integer :status, default: 0
      t.integer :sync_status, default: 0
      t.jsonb :error
      t.boolean :new_accounts_available, default: false
      t.datetime :consent_expiration
      t.string :aggregator_id
      t.string :item_id
      t.string :access_token
      t.string :cursor
      t.datetime :investments_last_synced_at

      t.timestamps
    end
  end
end
