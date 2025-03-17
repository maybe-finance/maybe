module ProviderTestHelper
  def provider_success_response(data)
    Provider::ProviderResponse.new(
      success?: true,
      data: data,
      error: nil
    )
  end

  def provider_error_response(error)
    Provider::ProviderResponse.new(
      success?: false,
      data: nil,
      error: error
    )
  end
end
