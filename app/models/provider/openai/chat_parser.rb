class Provider::Openai::ChatParser
  Error = Class.new(StandardError)

  def initialize(object)
    @object = object
  end

  def parsed
    ChatResponse.new(
      id: response_id,
      model: response_model,
      messages: messages,
      function_requests: function_requests
    )
  end

  private
    attr_reader :object

    ChatResponse = Provider::LlmConcept::ChatResponse
    ChatMessage = Provider::LlmConcept::ChatMessage
    ChatFunctionRequest = Provider::LlmConcept::ChatFunctionRequest

    def response_id
      object.dig("id")
    end

    def response_model
      object.dig("model")
    end

    def messages
      message_items = object.dig("output").filter { |item| item.dig("type") == "message" }

      message_items.map do |message_item|
        ChatMessage.new(
          id: message_item.dig("id"),
          output_text: message_item.dig("content").map do |content|
            text = content.dig("text")
            refusal = content.dig("refusal")
            text || refusal
          end.flatten.join("\n")
        )
      end
    end

    def function_requests
      function_items = object.dig("output").filter { |item| item.dig("type") == "function_call" }

      function_items.map do |function_item|
        ChatFunctionRequest.new(
          id: function_item.dig("id"),
          call_id: function_item.dig("call_id"),
          function_name: function_item.dig("name"),
          function_args: function_item.dig("arguments")
        )
      end
    end
end
