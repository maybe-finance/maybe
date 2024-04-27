class ApplicationMailer < ActionMailer::Base
  default from: Setting.email_sender
  layout "mailer"

  def mail(headers = {}, &block)
    if Rails.application.config.action_mailer.delivery_method = :smtp
      headers[:delivery_method_options] = smtp_settings
    end

    super(headers, &block)
  end

  private
    def smtp_settings
      {
        address:   Setting.smtp_host,
        port:      Setting.smtp_port,
        user_name: Setting.smtp_username,
        password:  Setting.smtp_password,
        tls:       ENV["TLS"] == "true"
        }
    end
end
