module Providable
  extend ActiveSupport::Concern

  KNOWN_PROVIDERS = %w[ synth null ]

  class_methods do
    def exchange_rates_provider
      provider :exchange_rates
    end

    private
      def provider(concept)
        "Provider::#{provider_name(concept).camelize}"
          .constantize
          .new(provider_api_key(concept))
      end

      def providers_config
        Rails.application.config_for "data_providers"
      end

      def provider_name(concept)
        providers_config[concept][:provider].presence_in(KNOWN_PROVIDERS) ||
          raise(ArgumentError, "Unknown provider for #{concept}")
      end

      def provider_api_key(concept)
        providers_config[concept][:key]
      end
  end

  def exchange_rates_provider
    self.class.exchange_rates_provider
  end
end
