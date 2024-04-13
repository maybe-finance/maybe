module Upgrader::Provided
  extend ActiveSupport::Concern
  include Providable

  class_methods do
    private
      def fetch_latest_upgrade_candidates_from_provider
        git_repository_provider.fetch_latest_upgrade_candidates
      end
  end
end
