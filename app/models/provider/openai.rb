class Provider::OpenAI < Provider
  include Assistant::Provideable

  def initialize(access_token)
    @client = ::OpenAI::Client.new(access_token: access_token)
  end

  def fetch_chat_response(params = {})
    provider_response do
      response = client.responses.create(parameters: params)

      Assistant::Provideable::ChatResponse.new(
        messages: response.dig("output").filter { |item| item.dig("type") == "message" }.map do |item|
          Message.new(
            ai_model: response.dig("model"),
            provider_id: item.dig("id"),
            status: normalized_status(item.dig("status")),
            role: "assistant",
            content: item.dig("content").map { |content| content.dig("text") }.join("\n")
          )
        end
      )
    end
  end

  def tools_config(assistant_functions)
    assistant_functions.map do |fn|
      {
        type: "function",
        function: {
          name: fn.name,
          description: fn.description,
          parameters: fn.parameters
        }
      }
    end
  end

  private
    attr_reader :client

    def normalized_status(openai_status)
      case openai_status
      when "in_progress"
        "pending"
      when "completed"
        "complete"
      when "incomplete"
        "failed"
      end
    end
end
