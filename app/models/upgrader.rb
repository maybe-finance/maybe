class Upgrader
  include Provided

  class << self
    def upgrade_to(candidate)
      config.deployer.deploy(candidate)
    end

    def available_upgrades
      return [] unless config.mode == :upgrades
      upgrade_candidates.select do |upgrade|
        upgrade.version > Maybe.version || (upgrade.version == Maybe.version && upgrade.commit_sha != Maybe.commit_sha)
      end
    end

    def completed_upgrades
      upgrade_candidates.select do |upgrade|
        upgrade.commit_sha == Maybe.commit_sha
      end
    end

    private
      def config
        @config ||= Upgrader::Config.new
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
