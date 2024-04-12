class Upgrader
  include Provided

  class << self
    attr_writer :config

    def config
      @config ||= Config.new
    end

    def attempt_latest_upgrade(upgrades_target)
      candidate = available_upgrade_by_type(upgrades_target)

      if candidate
        Rails.logger.info "Auto upgrading to #{candidate.type} #{candidate.commit_sha}..."
        upgrade_to(candidate)
      else
        Rails.logger.info "No auto upgrade available at this time"
      end
    end

    def upgrade_to(commit_or_upgrade)
      upgrade = commit_or_upgrade.is_a?(String) ? find_upgrade(commit_or_upgrade) : commit_or_upgrade
      config.deployer.deploy(upgrade)
    end

    def find_upgrade(commit)
      upgrade_candidates.find { |candidate| candidate.commit_sha == commit }
    end

    def available_upgrade
      available_upgrades.first
    end

    # Default to showing releases first, then commits
    def completed_upgrade
      completed_upgrades.find { |upgrade| upgrade.type == "release" } || completed_upgrades.first
    end

    private
      def available_upgrades
        upgrade_candidates.select(&:available?)
      end

      def completed_upgrades
        upgrade_candidates.select(&:complete?)
      end

      def upgrade_candidates
        latest_candidates = fetch_latest_upgrade_candidates_from_provider
        return [] unless latest_candidates

        commit_candidate = Upgrade.new("commit", latest_candidates[:commit])
        release_candidate = latest_candidates[:release] && Upgrade.new("release", latest_candidates[:release])

        [ release_candidate, commit_candidate ].compact.uniq { |candidate| candidate.commit_sha }
      end
  end
end
