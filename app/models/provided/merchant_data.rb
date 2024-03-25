class Provided::MerchantData
  include Providable, Retryable

  def initialize
    @provider = merchant_data_provider
  end

  def fetch(description:)
    retrying Provider::Base.known_transient_errors do
      response = provider.fetch_merchant_data(description:)

      Merchant.new name: response.name
    end
  end

  private
    attr_reader :provider
end
