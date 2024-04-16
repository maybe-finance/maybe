class Settings::HostingsController < ApplicationController
  before_action :verify_hosting_mode

  def show
  end

  def update
    if all_updates_valid?
      hosting_params.keys.each do |key|
        Setting.send("#{key}=", hosting_params[key].strip)
      end

      redirect_to edit_settings_hosting_path, notice: t(".success")
    else
      flash.now[:error] = @errors.first.message
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def all_updates_valid?
      @errors = ActiveModel::Errors.new(Setting)
      hosting_params.keys.each do |key|
        setting = Setting.new(var: key)
        setting.value = hosting_params[key].strip

        unless setting.valid?
          @errors.merge!(setting.errors)
        end
      end

      if hosting_params[:upgrades_mode] == "auto" && hosting_params[:render_deploy_hook].blank?
        @errors.add(:render_deploy_hook, t("settings.hosting.update.render_deploy_hook_error"))
      end

      @errors.empty?
    end

    def hosting_params
      params.require(:setting).permit(:render_deploy_hook, :upgrades_mode, :upgrades_target)
    end

    def verify_hosting_mode
      head :not_found unless self_hosted?
    end
end
