class Provider::Openai < Provider
  include Assistant::Provideable

  MODELS = %w[gpt-4o]

  def initialize(access_token)
    @client = ::OpenAI::Client.new(access_token: access_token)
  end

  def supports_model?(model)
    MODELS.include?(model)
  end

  def chat_response(chat_history:, model: nil, instructions: nil, functions: [])
    provider_response do
      response = ChatResponse.new(
        client: client,
        model: model,
        chat_history: chat_history,
        instructions: instructions,
        available_functions: functions
      )

      response.build
    end
  end

  private
    attr_reader :client
end
