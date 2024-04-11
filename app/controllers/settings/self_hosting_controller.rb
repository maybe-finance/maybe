class Settings::SelfHostingController < ApplicationController
  def edit
    redirect_to edit_settings_path unless self_hosted?
  end

  def update
    render "settings/edit", status: :forbidden and return unless self_hosted?

    if all_updates_valid?
      self_hosting_params.keys.each do |key|
        Setting.send("#{key}=", self_hosting_params[key].strip)
      end

      redirect_to edit_settings_self_hosting_path, notice: "Settings updated successfully."
    else
      flash.now[:error] = @errors.first.message
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def all_updates_valid?
      @errors = ActiveModel::Errors.new(Setting)
      self_hosting_params.keys.each do |key|
        setting = Setting.new(var: key)
        setting.value = self_hosting_params[key].strip

        unless setting.valid?
          @errors.merge!(setting.errors)
        end

        if key == "render_deploy_hook" && !deploy_hook_valid?(setting.value)
          @errors.add(:render_deploy_hook, "Invalid Render deploy hook URL")
        end
      end

      @errors.empty?
    end

    def deploy_hook_valid?(value)
      return true if value.blank?
      value.present? && value.start_with?("https://api.render.com/deploy/srv-")
    end

    def self_hosting_params
      params.require(:setting).permit(:render_deploy_hook)
    end
end
