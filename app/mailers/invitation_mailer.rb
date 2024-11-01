class InvitationMailer < ApplicationMailer
  def invite_email(invitation)
    @invitation = invitation
    @accept_url = accept_invitation_url(@invitation.token)

    mail(
      to: @invitation.email,
      subject: t(".subject", inviter: @invitation.inviter.display_name)
    )
  end
end
