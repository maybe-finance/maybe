class UpgradesController < ApplicationController
  before_action :verify_upgrades_enabled

  def acknowledge
    commit_sha = params[:id]
    upgrade = Upgrader.find_upgrade(commit_sha)

    if upgrade
      if upgrade.available?
        Current.user.acknowledge_upgrade_prompt(upgrade.commit_sha)
        flash[:notice] = t(".upgrade_dismissed")
      elsif upgrade.complete?
        Current.user.acknowledge_upgrade_alert(upgrade.commit_sha)
        flash[:notice] = t(".upgrade_complete_dismiss")
      else
        flash[:alert] = t(".upgrade_not_available")
      end
    else
      flash[:alert] = t(".upgrade_not_found")
    end

    redirect_back(fallback_location: root_path)
  end

  def deploy
    commit_sha = params[:id]
    upgrade = Upgrader.find_upgrade(commit_sha)

    unless upgrade
      flash[:alert] = t(".upgrade_not_found")
      return redirect_back(fallback_location: root_path)
    end

    prior_acknowledged_upgrade_commit_sha = Current.user.last_prompted_upgrade_commit_sha

    # Optimistically acknowledge the upgrade prompt
    Current.user.acknowledge_upgrade_prompt(upgrade.commit_sha)

    upgrade_result = Upgrader.upgrade_to(upgrade)

    if upgrade_result[:success]
      flash[:notice] = upgrade_result[:message]
    else
      # If the upgrade fails, revert to the prior acknowledged upgrade
      Current.user.acknowledge_upgrade_prompt(prior_acknowledged_upgrade_commit_sha)
      flash[:alert] = upgrade_result[:message]
    end

    redirect_back(fallback_location: root_path)
  end

  private
    def verify_upgrades_enabled
      head :not_found unless ENV["UPGRADES_ENABLED"] == "true"
    end
end
