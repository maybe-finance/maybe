module Upgrader::Provided
  extend ActiveSupport::Concern

  class_methods do
    private
      def fetch_latest_upgrade_candidates_from_provider
        git_repository_provider.fetch_latest_upgrade_candidates
      end

      def git_repository_provider
        Provider::Github.new
      end
  end
end
