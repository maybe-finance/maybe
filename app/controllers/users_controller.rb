class UsersController < ApplicationController
  before_action :set_user

  def update
    @user = Current.user

    if email_changed?
      if @user.initiate_email_change(user_params[:email])
        if Rails.application.config.app_mode.self_hosted? && !Setting.require_email_confirmation
          handle_redirect(t(".success"))
        else
          redirect_to settings_profile_path, notice: t(".email_change_initiated")
        end
      else
        redirect_to settings_profile_path, alert: @user.errors.full_messages.to_sentence
      end
    else
      @user.update!(user_params.except(:redirect_to, :delete_profile_image))
      @user.profile_image.purge if should_purge_profile_image?

      handle_redirect(t(".success"))
    end
  end

  def destroy
    if @user.deactivate
      Current.session.destroy
      redirect_to root_path, notice: t(".success")
    else
      redirect_to settings_profile_path, alert: @user.errors.full_messages.to_sentence
    end
  end

  private
    def handle_redirect(notice)
      case user_params[:redirect_to]
      when "onboarding_preferences"
        redirect_to preferences_onboarding_path
      when "home"
        redirect_to root_path
      when "preferences"
        redirect_to settings_preferences_path, notice: notice
      else
        redirect_to settings_profile_path, notice: notice
      end
    end

    def should_purge_profile_image?
      user_params[:delete_profile_image] == "1" &&
        user_params[:profile_image].blank?
    end

    def email_changed?
      user_params[:email].present? && user_params[:email] != @user.email
    end

    def user_params
      params.require(:user).permit(
        :first_name, :last_name, :email, :profile_image, :redirect_to, :delete_profile_image, :onboarded_at,
        family_attributes: [ :name, :currency, :country, :locale, :date_format, :timezone, :id, :data_enrichment_enabled ]
      )
    end

    def set_user
      @user = Current.user
    end
end
