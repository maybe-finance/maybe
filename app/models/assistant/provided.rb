module Assistant::Provided
  extend ActiveSupport::Concern

  AiModel = Data.define(:id, :name, :provider)

  def available_models
    [
      AiModel.new("openai-gpt-4o", "GPT-4o", Providers.openai)
    ]
  end

  def get_model(id)
    available_models.find { |model| model.id == id }
  end
end
