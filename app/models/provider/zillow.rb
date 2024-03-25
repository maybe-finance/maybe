class Provider::Zillow < Provider::Base
  def initialize(api_key)
    @api_key = api_key
  end

  def fetch_real_estate_valuation(address:)
    response = OpenStruct.new body: { data: { value: 1_000_000 } }.to_json, success?: true

    if response.success?
      RealEstateValuationResponse.new \
        value: JSON.parse(response.body).dig("data", "value"),
        raw_response: response
    else
      raise Provider::Base::ProviderError, <<~ERROR
        Failed to fetch real estate valuation from #{self.class}
          Status: #{response.status}
          Response: #{response.body.inspect}
      ERROR
    end
  end

  private
    attr_reader :api_key

    RealEstateValuationResponse = Struct.new(:value, :raw_response, keyword_init: true)
end
