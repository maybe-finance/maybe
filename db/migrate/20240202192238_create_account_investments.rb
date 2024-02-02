class CreateAccountInvestments < ActiveRecord::Migration[7.2]
  def change
    create_table :account_investments, id: :uuid do |t|
      t.timestamps
    end
  end
end
