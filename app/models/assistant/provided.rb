module Assistant::Provided
  extend ActiveSupport::Concern

  def provider_for_model(model)
    available_providers = [ Providers.openai ].compact
    available_providers.find { |provider| provider.supports_model?(model) }
  end
end
