module Providable
  extend ActiveSupport::Concern

  KNOWN_PROVIDERS = %w[ synth zillow null ]

  class_methods do
    def exchange_rates_provider
      provider_for :exchange_rates
    end

    def merchant_data_provider
      provider_for :merchant_data
    end

    def real_estate_valuations_provider
      provider_for :real_estate_valuations
    end

    private
      def provider_for(concept)
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

  def merchant_data_provider
    self.class.merchant_data_provider
  end

  def real_estate_valuations
    self.class.real_estate_valuations_provider
  end
end
