class AddMfaFieldsToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :otp_secret, :string
    add_column :users, :otp_required, :boolean, default: false, null: false
    add_column :users, :otp_backup_codes, :string, array: true, default: []

    add_index :users, :otp_secret, unique: true, where: "otp_secret IS NOT NULL"
  end
end
