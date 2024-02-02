class CreateAccountDepositories < ActiveRecord::Migration[7.2]
  def change
    create_table :account_depositories, id: :uuid do |t|
      t.timestamps
    end
  end
end
