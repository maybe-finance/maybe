class FixMobileDevicesUniqueConstraint < ActiveRecord::Migration[7.2]
  def change
    # Remove the old unique index on device_id only
    remove_index :mobile_devices, :device_id, if_exists: true

    # The composite unique index on user_id and device_id already exists
    # This allows the same device_id to be used by different users
  end
end
