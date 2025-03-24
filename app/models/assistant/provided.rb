module Assistant::Provided
  extend ActiveSupport::Concern

  def get_model_provider(ai_model)
    available_providers.find { |provider| provider.supports_model?(ai_model) }
  end

  private
    def available_providers
      [ Providers.openai ].compact
    end
end
