class Settings::ProfilesController < ApplicationController
  layout "settings"

  def show
    @user = Current.user
    @users = Current.family.users.order(:created_at)
    @pending_invitations = Current.family.invitations.pending
  end

  def destroy
    unless Current.user.admin?
      flash[:alert] = t("settings.profiles.destroy.not_authorized")
      redirect_to settings_profile_path
      return
    end

    @user = Current.family.users.find(params[:user_id])

    if @user == Current.user
      flash[:alert] = t("settings.profiles.destroy.cannot_remove_self")
      redirect_to settings_profile_path
      return
    end

    if @user.destroy
      flash[:notice] = t("settings.profiles.destroy.member_removed")
    else
      flash[:alert] = t("settings.profiles.destroy.member_removal_failed")
    end

    redirect_to settings_profile_path
  end
end
