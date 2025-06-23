class UpdateOutdatedTimezones < ActiveRecord::Migration[7.2]
  TIMEZONE_MAPPINGS = {
    "Europe/Kiev" => "Europe/Kyiv",
    "Asia/Calcutta" => "Asia/Kolkata",
    "Asia/Katmandu" => "Asia/Kathmandu",
    "Asia/Rangoon" => "Asia/Yangon",
    "Asia/Saigon" => "Asia/Ho_Chi_Minh",
    "Pacific/Ponape" => "Pacific/Pohnpei",
    "Pacific/Truk" => "Pacific/Chuuk"
  }.freeze

  def up
    TIMEZONE_MAPPINGS.each do |old_tz, new_tz|
      execute <<-SQL
        UPDATE families#{' '}
        SET timezone = '#{new_tz}'#{' '}
        WHERE timezone = '#{old_tz}'
      SQL
    end
  end

  def down
    TIMEZONE_MAPPINGS.each do |old_tz, new_tz|
      execute <<-SQL
        UPDATE families#{' '}
        SET timezone = '#{old_tz}'#{' '}
        WHERE timezone = '#{new_tz}'
      SQL
    end
  end
end
