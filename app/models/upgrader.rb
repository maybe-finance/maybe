class Upgrader
  include Provided

  class << self
    attr_writer :config

    def config
      @config ||= Config.new
    end

    def find_upgrade(commit)
      upgrade_candidates.find { |candidate| candidate.commit_sha == commit }
    end

    def upgrade_to(commit_or_upgrade)
      upgrade = commit_or_upgrade.is_a?(String) ? find_upgrade(commit_or_upgrade) : commit_or_upgrade
      config.deployer.deploy(upgrade)
    end

    def available_upgrades
      return [] unless config.mode == :enabled
      upgrade_candidates.select(&:available?)
    end

    def completed_upgrades
      upgrade_candidates.select(&:complete?)
    end

    private
      def upgrade_candidates
        return [] if config.mode == :disabled

        latest_candidates = fetch_latest_upgrade_candidates_from_provider
        return [] unless latest_candidates

        commit_candidate = Upgrade.new("commit", latest_candidates[:commit])
        release_candidate = latest_candidates[:release] && Upgrade.new("release", latest_candidates[:release])

        [ release_candidate, commit_candidate ].compact.uniq { |candidate| candidate.commit_sha }
      end
  end
end