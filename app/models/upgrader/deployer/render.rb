class Upgrader::Deployer::Render
  def deploy(upgrade)
    if Setting.render_deploy_hook.blank?
      return {
        success: false,
        message: I18n.t("upgrader.deployer.render.error_message_not_set"),
        troubleshooting_url: "/settings/self_hosting/edit"
      }
    end

    Rails.logger.info I18n.t("upgrader.deployer.render.deploy_log_info", type: upgrade.type, commit_sha: upgrade.commit_sha)

    begin
      uri = URI.parse(Setting.render_deploy_hook)
      uri.query = [ uri.query, "ref=#{upgrade.commit_sha}" ].compact.join("&")
      response = Faraday.post(uri.to_s)

      unless response.success?
        Rails.logger.error I18n.t("upgrader.deployer.render.deploy_log_error", type: upgrade.type, commit_sha: upgrade.commit_sha, error_message: response.body)
        return default_error_response
      end

      {
        success: true,
        message: I18n.t("upgrader.deployer.render.success_message", commit_sha: upgrade.commit_sha.slice(0, 7))
      }
    rescue => e
      Rails.logger.error I18n.t("upgrader.deployer.render.deploy_log_error", type: upgrade.type, commit_sha: upgrade.commit_sha, error_message: e.message)
      default_error_response
    end
  end

  private
    def default_error_response
      {
        success: false,
        message: I18n.t("upgrader.deployer.render.error_message_failed_deploy"),
        troubleshooting_url: I18n.t("upgrader.deployer.render.troubleshooting_url")
      }
    end
end
