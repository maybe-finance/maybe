class Provider::OpenAI < Provider
  include Assistant::Provideable

  AVAILABLE_MODELS = %w[gpt-4o]

  def initialize(access_token)
    @client = ::OpenAI::Client.new(access_token: access_token)
  end

  def supports_model?(model)
    AVAILABLE_MODELS.include?(model)
  end

  def chat_response(messages:, model: nil, functions: [], instructions: nil)
    provider_response do
      validate_model!(model)

      response = client.responses.create(
        parameters: {
          model: model,
          input: messages.map { |msg| { role: msg.role, content: msg.content } },
          tools: build_tools(functions),
          instructions: instructions
        }
      )

      Assistant::Provideable::ChatResponse.new(
        messages: response.dig("output").filter { |item| item.dig("type") == "message" }.map do |item|
          Message.new(
            ai_model: response.dig("model"),
            provider_id: item.dig("id"),
            status: normalize_status(item.dig("status")),
            role: "assistant",
            content: item.dig("content").map { |content| content.dig("text") }.join("\n")
          )
        end
      )
    end
  end

  private
    attr_reader :client, :model, :functions

    def validate_model!(model)
      raise "Model #{model} not supported for Provider::OpenAI" unless AVAILABLE_MODELS.include?(model)
      model
    end

    def build_tools(functions = [])
      functions.map do |fn|
        {
          type: "function",
          name: fn.name,
          description: fn.description,
          parameters: fn.parameters,
          strict: true
        }
      end
    end

    # Normalize to our internal message status values
    def normalize_status(status)
      case status
      when "in_progress"
        "pending"
      when "completed"
        "complete"
      when "incomplete"
        "failed"
      end
    end
end
