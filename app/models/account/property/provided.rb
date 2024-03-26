module Account::Property::Provided
  include Providable

  def fetch_valuation_from_provider
    address = "not implemented"
    response = real_estate_valuations_provider.fetch_real_estate_valuation(address: address)

    if response.success?
      Valuation.new value: response.value
    else
      # do something else
    end
  end
end
