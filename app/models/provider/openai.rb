class Provider::Openai < Provider
  include Assistant::Provideable

  Error = Class.new(StandardError)

  MODELS = %w[gpt-4o]

  def initialize(access_token)
    @client = ::OpenAI::Client.new(access_token: access_token)
  end

  def supports_model?(model)
    MODELS.include?(model)
  end

  def chat_response(message, instructions: nil, available_functions: [])
    provider_response do
      processor = ChatResponseProcessor.new(
        client: client,
        message: message,
        instructions: instructions,
        available_functions: available_functions
      )

      processor.process
    end
  end

  private
    attr_reader :client

    def transform_error(error)
      if error.is_a?(Faraday::Error)
        Error.new(error.response[:body].dig("error", "message"))
      else
        error
      end
    end
end
