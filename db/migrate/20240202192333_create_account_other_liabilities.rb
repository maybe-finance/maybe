class CreateAccountOtherLiabilities < ActiveRecord::Migration[7.2]
  def change
    create_table :account_other_liabilities, id: :uuid do |t|
      t.timestamps
    end
  end
end
