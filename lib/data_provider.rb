module DataProvider
    class ExchangeRateProviderNotSet < StandardError; end

    class << self
        attr_reader :exchange_rate_provider

        def exchange_rate_provider=(provider)
            unless provider.is_a?(DataProvider::ExchangeRate::Provideable)
                raise ArgumentError, "Exchange rate provider must include ExchangeRateProvider"
            end
            @exchange_rate_provider = provider
        end

        def exchange_rate(from_currency, to_currency, date = Date.current)
            raise ExchangeRateProviderNotSet unless exchange_rate_provider
            exchange_rate_provider.exchange_rate(from_currency, to_currency, date)
        end
    end
end
