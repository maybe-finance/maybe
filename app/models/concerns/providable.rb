# `Providable` serves as an extension point for integrating multiple providers.
# For an example of a multi-provider, multi-concept implementation,
# see: https://github.com/maybe-finance/maybe/pull/561

module Providable
  extend ActiveSupport::Concern

  class_methods do
    def exchange_rates_provider
      Provider::Synth.new
    end

    def git_repository_provider
      Provider::Github.new \
        name: ENV.fetch("GITHUB_REPO_NAME", "maybe"),
        owner: ENV.fetch("GITHUB_REPO_OWNER", "maybe-finance"),
        branch: ENV.fetch("GITHUB_REPO_BRANCH", "main")
    end
  end
end
