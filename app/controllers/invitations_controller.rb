class InvitationsController < ApplicationController
  skip_authentication only: :accept
  def new
    @invitation = Invitation.new
  end

  def create
    @invitation = Current.family.invitations.build(invitation_params)
    @invitation.inviter = Current.user

    if @invitation.role == "admin" && !Current.user.admin?
      @invitation.role = "member"
    end

    if @invitation.save
      InvitationMailer.invite_email(@invitation).deliver_later
      flash[:notice] = t(".success")
    else
      flash[:alert] = t(".failure")
    end

    redirect_to settings_profile_path
  end

  def accept
    @invitation = Invitation.pending.find_by!(token: params[:id])
    redirect_to new_registration_path(invitation: @invitation.token)
  end

  private

    def invitation_params
      base_params = params.require(:invitation).permit(:email)

      if params[:invitation][:role].in?(%w[admin member])
        base_params[:role] = params[:invitation][:role]
      else
        base_params[:role] = "member"
      end

      base_params
    end
end
