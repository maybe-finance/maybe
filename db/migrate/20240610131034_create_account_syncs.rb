class CreateAccountSyncs < ActiveRecord::Migration[7.2]
  def change
    create_table :account_syncs, id: :uuid do |t|
      t.references :account, null: false, foreign_key: true, type: :uuid, foreign_key: { on_delete: :cascade}
      t.jsonb :result
      t.text :error

      t.timestamps
    end
  end
end
