class Provider::Openai < Provider
  include Assistant::Provideable

  MODELS = %w[gpt-4o]

  def initialize(access_token)
    @client = ::OpenAI::Client.new(access_token: access_token)
  end

  def supports_model?(model)
    MODELS.include?(model)
  end

  def chat_response(message, instructions: nil, available_functions: [], streamer: nil)
    with_provider_response do
      processor = ChatResponseProcessor.new(
        client: client,
        message: message,
        instructions: instructions,
        available_functions: available_functions,
        streamer: streamer
      )

      processor.process
    end
  end

  private
    attr_reader :client
end
