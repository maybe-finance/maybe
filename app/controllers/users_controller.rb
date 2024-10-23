class UsersController < ApplicationController
  before_action :set_user

  def update
    @user = Current.user

    @user.update!(user_params.except(:redirect_to, :delete_profile_image))
    @user.profile_image.purge if should_purge_profile_image?

    handle_redirect(t(".success"))
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

    def user_params
      params.require(:user).permit(
        :first_name, :last_name, :profile_image, :redirect_to, :delete_profile_image, :onboarded_at,
        family_attributes: [ :name, :currency, :country, :locale, :id ]
      )
    end

    def set_user
      @user = Current.user
    end
end
