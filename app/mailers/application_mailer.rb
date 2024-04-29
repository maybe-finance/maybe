class ApplicationMailer < ActionMailer::Base
  layout "mailer"

  after_action :set_self_host_settings, if: -> { ENV["SELF_HOSTING_ENABLED"] == "true" && Rails.application.config.action_mailer.delivery_method = :smtp }

  private

  def set_self_host_settings
    mail.from = Setting.email_sender
    mail.delivery_method.settings.merge!({ address: Setting.smtp_host,
                                           port: Setting.smtp_port,
                                           user_name: Setting.smtp_username,
                                           password: Setting.smtp_password,
                                           tls: ENV.fetch("SMTP_TLS_ENABLED", "true") == "true" })
  end
end
