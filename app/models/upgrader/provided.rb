module Upgrader::Provided
  extend ActiveSupport::Concern

  class_methods do
    private
      def fetch_latest_upgrade_candidates_from_provider
        Providers.github.fetch_latest_upgrade_candidates
      end
  end
end
