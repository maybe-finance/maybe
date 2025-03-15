class Settings::HostingsController < ApplicationController
  layout "settings"

  before_action :raise_if_not_self_hosted
  before_action :ensure_admin, only: :clear_cache

  def show
    @synth_usage = Providers.synth.usage
  end

  def update
    if hosting_params[:upgrades_setting].present?
      mode = hosting_params[:upgrades_setting] == "manual" ? "manual" : "auto"
      target = hosting_params[:upgrades_setting] == "commit" ? "commit" : "release"

      Setting.upgrades_mode = mode
      Setting.upgrades_target = target
    end

    if hosting_params.key?(:render_deploy_hook)
      Setting.render_deploy_hook = hosting_params[:render_deploy_hook]
    end

    if hosting_params.key?(:require_invite_for_signup)
      Setting.require_invite_for_signup = hosting_params[:require_invite_for_signup]
    end

    if hosting_params.key?(:require_email_confirmation)
      Setting.require_email_confirmation = hosting_params[:require_email_confirmation]
    end

    if hosting_params.key?(:synth_api_key)
      Setting.synth_api_key = hosting_params[:synth_api_key]
    end

    redirect_to settings_hosting_path, notice: t(".success")
  rescue ActiveRecord::RecordInvalid => error
    flash.now[:alert] = t(".failure")
    render :show, status: :unprocessable_entity
  end

  def clear_cache
    DataCacheClearJob.perform_later(Current.family)
    redirect_to settings_hosting_path, notice: t(".cache_cleared")
  end

  private
    def hosting_params
      params.require(:setting).permit(:render_deploy_hook, :upgrades_setting, :require_invite_for_signup, :require_email_confirmation, :synth_api_key)
    end

    def raise_if_not_self_hosted
      raise "Settings not available on non-self-hosted instance" unless self_hosted?
    end

    def ensure_admin
      redirect_to settings_hosting_path, alert: t(".not_authorized") unless Current.user.admin?
    end
end
