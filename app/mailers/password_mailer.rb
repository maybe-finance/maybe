class PasswordMailer < ApplicationMailer
  def password_reset
    @user = params[:user]
    @subject = t(".subject")
    @cta = t(".cta")

    mail to: @user.email, subject: @subject
  end
end
