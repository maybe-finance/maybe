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
    @confirmation_url = new_email_confirmation_url(token: @user.generate_token_for(:email_confirmation))

    mail to: @user.unconfirmed_email, subject: @subject
  end
end
