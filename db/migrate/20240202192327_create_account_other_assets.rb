class CreateAccountOtherAssets < ActiveRecord::Migration[7.2]
  def change
    create_table :account_other_assets, id: :uuid do |t|
      t.timestamps
    end
  end
end
