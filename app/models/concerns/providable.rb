# `Providable` serves as an extension point for integrating multiple providers.
# For an example of a multi-provider, multi-concept implementation,
# see: https://github.com/maybe-finance/maybe/pull/561

module Providable
  extend ActiveSupport::Concern

  class_methods do
    def exchange_rates_provider
      Provider::Synth
    end

    def git_repository_provider
      Provider::Github.new
    end
  end
end
