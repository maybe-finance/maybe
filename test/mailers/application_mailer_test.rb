require "test_helper"

class ApplicationMailerTest < ActionMailer::TestCase
  setup do
    class TestMailer < ApplicationMailer
      def test_email
        mail(to: "testto@email.com", from: "testfrom@email.com", subject: "Test email subject", body: "Test email body")
      end
    end
  end

  test "should use self host settings when self host enabled" do
    with_self_hosting do
      smtp_host = "smtp.example.com"
      smtp_port = 466
      smtp_username = "user@example.com"
      smtp_password = "password"
      email_sender = "notification@example.com"

      smtp_settings_from_settings = { address: smtp_host,
                                      port: smtp_port,
                                      user_name: smtp_username,
                                      password: smtp_password }

      Setting.stubs(:smtp_host).returns(smtp_host)
      Setting.stubs(:smtp_port).returns(smtp_port)
      Setting.stubs(:smtp_username).returns(smtp_username)
      Setting.stubs(:smtp_password).returns(smtp_password)
      Setting.stubs(:email_sender).returns(email_sender)

      TestMailer.test_email.deliver_now
      assert_emails 1
      assert_equal smtp_settings_from_settings, ActionMailer::Base.deliveries.first.delivery_method.settings.slice(:address, :port, :user_name, :password)
    end
  end

  test "should use regular env settings when self host disabled" do
      TestMailer.test_email.deliver_now

      assert_emails 1
      assert_nil ActionMailer::Base.deliveries.first.delivery_method.settings[:address]
  end
end
