class Settings::HostingsController < SettingsController
  before_action :raise_if_not_self_hosted

  def show
    @synth_usage = Current.family.synth_usage
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

    if hosting_params.key?(:synth_api_key)
      Setting.synth_api_key = hosting_params[:synth_api_key]
    end

    if hosting_params.key?(:data_enrichment_enabled)
      Setting.data_enrichment_enabled = hosting_params[:data_enrichment_enabled]
    end

    redirect_to settings_hosting_path, notice: t(".success")
  rescue ActiveRecord::RecordInvalid => error
    flash.now[:alert] = t(".failure")
    render :show, status: :unprocessable_entity
  end

  private
    def hosting_params
      params.require(:setting).permit(:render_deploy_hook, :upgrades_setting, :require_invite_for_signup, :synth_api_key, :data_enrichment_enabled)
    end

    def raise_if_not_self_hosted
      raise "Settings not available on non-self-hosted instance" unless self_hosted?
    end
end
