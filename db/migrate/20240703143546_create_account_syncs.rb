class CreateAccountSyncs < ActiveRecord::Migration[7.2]
  def change
    create_table :account_syncs, id: :uuid do |t|
      t.string :status, null: false, default: "pending"
      t.date :start_date

      t.string :error
      t.text :warnings, array: true, default: []

      t.timestamps
    end
  end
end
