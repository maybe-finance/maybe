class ApplicationMailer < ActionMailer::Base
  default from: ENV["EMAIL_SENDER"] if ENV["EMAIL_SENDER"].present?
  layout "mailer"
end
