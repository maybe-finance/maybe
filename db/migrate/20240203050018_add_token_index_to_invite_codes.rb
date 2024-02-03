class AddTokenIndexToInviteCodes < ActiveRecord::Migration[7.2]
  def change
    add_index :invite_codes, :token, unique: true
  end
end
