module Provider::Openai::Parser
  extend ActiveSupport::Concern

  private
    def extract_id(chat_response)
      chat_response.dig("id")
    end

    def extract_model(chat_response)
      chat_response.dig("model")
    end

    def extract_messages(chat_response)
      message_items = chat_response.dig("output").filter { |item| item.dig("type") == "message" }

      message_items.map do |message_item|
        output_text = message_item.dig("content").map do |content|
          text = content.dig("text")
          refusal = content.dig("refusal")

          text || refusal
        end.flatten.join("\n")

        {
          id: message_item.dig("id"),
          output_text: output_text
        }
      end
    end

    def extract_function_requests(chat_response)
      chat_response.dig("output").filter { |item| item.dig("type") == "function_call" }.map do |function_call|
        {
          id: function_call.dig("id"),
          call_id: function_call.dig("call_id"),
          name: function_call.dig("name"),
          arguments: function_call.dig("arguments")
        }
      end
    end
end
