class Provided::RealEstateValuations
  include Providable, Retryable

  def initialize
    @provider = real_estate_valuations_provider
  end

  def fetch(address:)
    retrying Provider::Base.known_transient_errors do
      response = provider.fetch_real_estate_valuation(address:)

      Valuation.new value: response.value
    end
  end

  private
    attr_reader :provider
end
