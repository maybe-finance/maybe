class Provider::Synth
  class << self
    include Retryable

    attr_accessor :configuration

    def initialized?
      configuration.api_key.present?
    end

    def configure
      self.configuration ||= Configuration.new
      yield(configuration)
    end

    def fetch_exchange_rate(from:, to:, date:)
      retrying Provider::Base.known_transient_errors do |on_last_attempt|
        response = Faraday.get("#{base_url}/rates/historical") do |req|
          req.headers["Authorization"] = "Bearer #{configuration.api_key}"
          req.params["date"] = date.to_s
          req.params["from"] = from
          req.params["to"] = to
        end

        if response.success?
          ExchangeRateResponse.new \
            rate: JSON.parse(response.body).dig("data", "rates", to),
            success?: true,
            raw_response: response
        else
          if on_last_attempt
            ExchangeRateResponse.new \
              success?: false,
              error: build_error(response),
              raw_response: response
          else
            raise build_error(response)
          end
        end
      end
    end

    private
      class Configuration
        attr_accessor :api_key
      end

      ExchangeRateResponse = Struct.new :rate, :success?, :error, :raw_response, keyword_init: true

      def base_url
        "https://api.synthfinance.com"
      end

      def build_error(response)
        Provider::Base::ProviderError.new(<<~ERROR)
          Failed to fetch exchange rate from #{self}
            Status: #{response.status}
            Body: #{response.body.inspect}
        ERROR
      end
  end
end
