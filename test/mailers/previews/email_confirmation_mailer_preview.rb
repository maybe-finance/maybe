# Preview all emails at http://localhost:3000/rails/mailers/email_confirmation_mailer
class EmailConfirmationMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/email_confirmation_mailer/confirmation_email
  def confirmation_email
    EmailConfirmationMailer.confirmation_email
  end
end
