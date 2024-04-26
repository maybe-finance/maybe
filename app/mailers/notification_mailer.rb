class NotificationMailer < ApplicationMailer
  def test_email(to)
    mail(to: to, subject: t(".test_email_subject"), body: t(".test_email_body"))
  end
end
