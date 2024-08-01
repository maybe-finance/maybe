# `Providable` serves as an extension point for integrating multiple providers.
# For an example of a multi-provider, multi-concept implementation,
# see: https://github.com/maybe-finance/maybe/pull/561

module Providable
  extend ActiveSupport::Concern

  class_methods do
    def security_prices_provider
      synth_provider
    end

    def exchange_rates_provider
      synth_provider
    end

    def git_repository_provider
      Provider::Github.new
    end

    private

      def synth_provider
        @synth_provider ||= begin
                              api_key = ENV["SYNTH_API_KEY"]
                              api_key.present? ? Provider::Synth.new(api_key) : nil
                            end
      end
  end
end
