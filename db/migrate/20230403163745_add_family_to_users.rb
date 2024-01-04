class AddFamilyToUsers < ActiveRecord::Migration[7.1]
  def change
    add_reference :users, :family, null: false, foreign_key: true, type: :uuid
  end
end
