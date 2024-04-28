class ApplicationMailer < ActionMailer::Base
  default from: ENV["EMAIL_SENDER"]
  layout "mailer"

  before_action :set_self_host_email_sender, if: -> { ENV["SELF_HOSTING_ENABLED"] == "true" }
  after_action :set_self_host_smtp_settings, if: -> { ENV["SELF_HOSTING_ENABLED"] == "true" && Rails.application.config.action_mailer.delivery_method = :smtp }

  private

  def set_self_host_email_sender
    self.class.default(from: Setting.email_sender)
  end

  def set_self_host_smtp_settings
    mail.delivery_method.settings.merge!({ address: Setting.smtp_host,
                                           port: Setting.smtp_port,
                                           user_name: Setting.smtp_username,
                                           password: Setting.smtp_password,
                                           tls: ENV["SMTP_TLS_ENABLED"] == "true" })
  end
end
