module Transaction::Provided
  include Providable

  def fetch_merchant_data_from_provider
    response = merchant_data_provider.fetch_merchant_data(description: notes)

    if response.success?
      Merchant.new \
        name: response.name,
        website: response.website,
        logo_url: response.logo_url
    else
      # do something else
    end
  end
end
