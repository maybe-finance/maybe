class AddFieldsToAccountCredits < ActiveRecord::Migration[7.2]
  def change
    add_column :account_credits, :card_type, :string
    add_column :account_credits, :limit, :integer
  end
end
