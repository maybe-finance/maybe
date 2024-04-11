class UpgradesController < ApplicationController
  def acknowledge
    commit_sha = params[:id]
    upgrade = Upgrader.find_upgrade(commit_sha)

    if upgrade
      if upgrade.available?
        Current.user.acknowledge_upgrade_prompt(upgrade.commit_sha)
      elsif upgrade.complete?
        Current.user.acknowledge_upgrade_alert(upgrade.commit_sha)
      else
        raise "Upgrade is neither available nor complete"
      end

      render json: { message: "Upgrade acknowledged" }
    else
      render json: { error: "Upgrade not found" }, status: 404
    end
  end

  def deploy
    commit_sha = params[:id]
    upgrade = Upgrader.find_upgrade(commit_sha)

    unless upgrade
      return render json: { error: "Upgrade not found" }, status: 404
    end

    prior_acknowledged_upgrade_commit_sha = Current.user.last_prompted_upgrade_commit_sha

    # Optimistically acknowledge the upgrade prompt
    Current.user.acknowledge_upgrade_prompt(upgrade.commit_sha)

    if Upgrader.upgrade_to(upgrade)
      render json: { message: "Upgrade deployed" }
    else
      # If the upgrade fails, revert to the prior acknowledged upgrade
      Current.user.acknowledge_upgrade_prompt(prior_acknowledged_upgrade_commit_sha)
      render json: { error: "Upgrade failed" }, status: 500
    end
  end
end
