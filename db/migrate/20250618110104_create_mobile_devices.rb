class CreateMobileDevices < ActiveRecord::Migration[7.2]
  def change
    create_table :mobile_devices, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :device_id
      t.string :device_name
      t.string :device_type
      t.string :os_version
      t.string :app_version
      t.datetime :last_seen_at

      t.timestamps
    end
    add_index :mobile_devices, :device_id, unique: true
    add_index :mobile_devices, [ :user_id, :device_id ], unique: true
  end
end
