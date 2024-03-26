class Provider::Zillow
  include Retryable

  def initialize(api_key)
    @api_key = api_key || ENV["ZILLOW_API_KEY"]
  end

  def fetch_real_estate_valuation(address:)
    retrying Provider::Base.known_transient_errors do |on_last_attempt|
      response = OpenStruct.new body: { data: { value: 1_000_000 } }.to_json, success?: true

      if response.success?
        RealEstateValuationResponse.new \
          value: JSON.parse(response.body).dig("data", "value"),
          success?: true,
          raw_response: response
      else
        if on_last_attempt
          RealEstateValuationResponse.new \
            value: nil,
            success?: false,
            raw_response: response
        else
          raise_error "Failed to fetch real estate valuation from #{self.class}", response
        end
      end
    end
  end

  private
    attr_reader :api_key

    RealEstateValuationResponse = Struct.new(:value, :success?, :raw_response, keyword_init: true)

    def raise_error(message, response)
      raise Provider::Base::ProviderError, <<~ERROR
        #{message}
          Status: #{response.status}
          Body: #{response.body.inspect}
      ERROR
    end
end
