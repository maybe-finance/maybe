require "test_helper"

class ApplicationMailerTest < ActionMailer::TestCase
  setup do
    ENV["SMTP_TLS_ENABLED"] = "true"
    ENV["SMTP_ADDRESS"] = "smtp.example.com"
    ENV["SMTP_PORT"] = "465"
    ENV["SMTP_USERNAME"] = "user@example.env"
    ENV["SMTP_PASSWORD"] = "password.env"
    ENV["EMAIL_SENDER"] = "notification@example.env"
    @smtp_settings_from_env = { address: ENV["SMTP_ADDRESS"],
                                port: ENV["SMTP_PORT"],
                                user_name: ENV["SMTP_USERNAME"],
                                password: ENV["SMTP_PASSWORD"],
                                tls: ENV["SMTP_TLS_ENABLED"] == "true" }

    Setting.smtp_host = "smtp.example.com"
    Setting.smtp_port = 466
    Setting.smtp_username = "user@example.com"
    Setting.smtp_password = "password"
    Setting.email_sender = "notification@example.com"
    @smtp_settings_from_settings = { address: Setting.smtp_host,
                                     port: Setting.smtp_port,
                                     user_name: Setting.smtp_username,
                                     password: Setting.smtp_password,
                                     tls: ENV["SMTP_TLS_ENABLED"] == "true" }

    ActionMailer::Base.delivery_method = :smtp
    ActionMailer::Base.smtp_settings = {
      address: ENV["SMTP_ADDRESS"],
      port: ENV["SMTP_PORT"],
      user_name: ENV["SMTP_USERNAME"],
      password: ENV["SMTP_PASSWORD"],
      tls: ENV["SMTP_TLS_ENABLED"] == "true",
    }

    ApplicationMailer.define_method(:test_email) { mail(to: "user@example.com", subject: "Test email subject", body: "Test email body") }
  end

  teardown do
    ApplicationMailer.remove_method(:test_email)
    ENV["SELF_HOSTING_ENABLED"] = "false"
    ActionMailer::Base.smtp_settings = {}
    ActionMailer::Base.delivery_method = :test
  end

  test "should return ENV config when self hosting is not enabled" do
    ENV["SELF_HOSTING_ENABLED"] = "false"
    email = ApplicationMailer.test_email
    assert_equal @smtp_settings_from_env, email.delivery_method.settings.slice(:address, :port, :user_name, :password, :tls)
    assert_equal ENV["EMAIL_SENDER"], email.from.first
  end

  test "should return setting config when self hosting is enabled" do
    ENV["SELF_HOSTING_ENABLED"] = "true"
    email = ApplicationMailer.test_email
    assert_equal @smtp_settings_from_settings, email.delivery_method.settings.slice(:address, :port, :user_name, :password, :tls)
    assert_equal Setting.email_sender, email.from.first
  end
end
