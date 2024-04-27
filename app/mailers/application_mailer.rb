class ApplicationMailer < ActionMailer::Base
  default from: ENV["EMAIL_SENDER"]
  layout "mailer"

  before_action :set_self_host_settings, if: -> { ENV["SELF_HOSTING_ENABLED"] == "true" }

  private

  def set_self_host_settings
    ActionMailer::Base.default(from: Setting.email_sender)
    if Rails.application.config.action_mailer.delivery_method = :smtp
      set_self_host_smtp_settings
    end
  end

  def set_self_host_smtp_settings
    ActionMailer::Base.smtp_settings = { address: Setting.smtp_host,
                                         port: Setting.smtp_port,
                                         user_name: Setting.smtp_username,
                                         password: Setting.smtp_password,
                                         tls: ENV["SMTP_TLS_ENABLED"] == "true" }
  end
end
