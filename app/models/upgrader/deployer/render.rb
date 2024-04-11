class Upgrader::Deployer::Render
  def deploy(upgrade)
    if Setting.render_deploy_hook.blank?
      return {
        success: false,
        message: "Render deploy hook URL is not set",
        troubleshooting_url: "/settings/self_hosting/edit"
      }
    end

    Rails.logger.info "Deploying #{upgrade.type} #{upgrade.commit_sha} to Render..."

    begin
      response = Faraday.post("#{Setting.render_deploy_hook}?ref=#{upgrade.commit_sha}")

      unless response.success?
        Rails.logger.error "Failed to deploy #{upgrade.type} #{upgrade.commit_sha} to Render: #{response.body}"
        return default_error_response
      end

      {
        success: true,
        message: "Triggered deployment to Render for commit: #{upgrade.commit_sha.slice(0, 7)}"
      }
    rescue => e
      Rails.logger.error "Failed to deploy #{upgrade.type} #{upgrade.commit_sha} to Render: #{e.message}"
      default_error_response
    end
  end

  private
    def default_error_response
      {
        success: false,
        message: "Failed to deploy to Render",
        troubleshooting_url: "https://render.com/docs/deploy-hooks"
      }
    end
end
