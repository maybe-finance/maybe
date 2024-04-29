require "test_helper"

class AccountTest < ActiveSupport::TestCase
  test "#send_test_email return true if all smtp settings are populated" do
    Setting.smtp_host = "smtp.example.com"
    Setting.smtp_port = 466
    Setting.smtp_username = "user@example.com"
    Setting.smtp_password = "notification@example.com"
    Setting.email_sender = "password"

    assert Setting.smtp_settings_populated?
  end

  test "#send_test_email return false if one smtp settings is not populated" do
    Setting.smtp_host = ""
    Setting.smtp_port = 466
    Setting.smtp_username = "user@example.com"
    Setting.smtp_password = "notification@example.com"
    Setting.email_sender = "password"

    refute Setting.smtp_settings_populated?
  end
end
