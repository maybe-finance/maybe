class UsersController < ApplicationController
  before_action :set_user
  before_action :ensure_admin, only: :reset

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
        error_message = @user.errors.any? ? @user.errors.full_messages.to_sentence : t(".email_change_failed")
        redirect_to settings_profile_path, alert: error_message
      end
    else
      was_ai_enabled = @user.ai_enabled
      @user.update!(user_params.except(:redirect_to, :delete_profile_image))
      @user.profile_image.purge if should_purge_profile_image?

      # Add a special notice if AI was just enabled
      notice = if !was_ai_enabled && @user.ai_enabled
        "AI Assistant has been enabled successfully."
      else
        t(".success")
      end

      respond_to do |format|
        format.html { handle_redirect(notice) }
        format.json { head :ok }
      end
    end
  end

  def reset
    FamilyResetJob.perform_later(Current.family)
    redirect_to settings_profile_path, notice: t(".success")
  end

  def destroy
    if @user.deactivate
      Current.session.destroy
      redirect_to root_path, notice: t(".success")
    else
      redirect_to settings_profile_path, alert: @user.errors.full_messages.to_sentence
    end
  end

  def rule_prompt_settings
    @user.update!(rule_prompt_settings_params)
    redirect_back_or_to settings_profile_path
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
      when "goals"
        redirect_to goals_onboarding_path
      when "trial"
        redirect_to trial_onboarding_path
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

    def rule_prompt_settings_params
      params.require(:user).permit(:rule_prompt_dismissed_at, :rule_prompts_disabled)
    end

    def user_params
      params.require(:user).permit(
        :first_name, :last_name, :email, :profile_image, :redirect_to, :delete_profile_image, :onboarded_at,
        :show_sidebar, :default_period, :show_ai_sidebar, :ai_enabled, :theme, :set_onboarding_preferences_at, :set_onboarding_goals_at,
        family_attributes: [ :name, :currency, :country, :locale, :date_format, :timezone, :id ],
        goals: []
      )
    end

    def set_user
      @user = Current.user
    end

    def ensure_admin
      redirect_to settings_profile_path, alert: I18n.t("users.reset.unauthorized") unless Current.user.admin?
    end
end
