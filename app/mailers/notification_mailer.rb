class NotificationMailer < ApplicationMailer
  def test_email
    mail(to: params[:user].email, subject: t(".test_email_subject"), body: t(".test_email_body"))
  end
end
