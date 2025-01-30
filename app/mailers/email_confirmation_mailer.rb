class EmailConfirmationMailer < ApplicationMailer
  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.email_confirmation_mailer.confirmation_email.subject
  #
  def confirmation_email
    @user = params[:user]
    @subject = t(".subject")
    @cta = t(".cta")
    @confirmation_url = confirm_email_url(@user.email_confirmation_token)

    mail to: @user.unconfirmed_email, subject: @subject
  end
end
