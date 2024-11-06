class ApplicationMailer < ActionMailer::Base
  default from: email_address_with_name(ENV.fetch("EMAIL_SENDER", "sender@maybe.local"), "Maybe Finance")
  layout "mailer"
end
