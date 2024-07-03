class CreateAccountSyncs < ActiveRecord::Migration[7.2]
  def change
    create_table :account_syncs, id: :uuid do |t|
      t.string :status
      t.date :start_date

      t.timestamps
    end
  end
end
