module ExchangeRate::Provided
  extend ActiveSupport::Concern

  class_methods do
    def provider
      Providers.synth
    end

    def sync_provider_rates(from:, to:, start_date:, end_date: Date.current)
      # TODO
    end
  end
end
