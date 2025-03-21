class Provider::OpenAI < Provider
  include Assistant::Provideable

  def initialize(access_token)
    @client = ::OpenAI::Client.new(access_token: access_token)
  end

  def supports_model?(model)
    AVAILABLE_MODELS.include?(model)
  end

  def chat_response(messages:, model: nil, instructions: nil, functions: [])
    provider_response do
      response = client.responses.create(
        parameters: {
          model: model,
          input: build_input(messages),
          tools: build_available_tools(functions),
          instructions: instructions
        }
      )

      Assistant::Provideable::ChatResponse.new(
        message: Message.new(
          ai_model: response.dig("model"),
          provider_id: response.dig("id"),
          role: "assistant",
          content: extract_content(response),
        ),
        tool_calls: extract_tool_calls(response)
      )
    end
  end

  private
    attr_reader :client, :model, :functions

    # Builds input based on chat history and nested tool calls within messages
    def build_input(messages)
      input = []

      messages.each do |msg|
        # Append completed messages.  Messages with tool calls will be "pending"
        if msg.complete?
          input << { role: msg.role, content: msg.content }
        end

        # Append both the tool call and the tool call result with its correlation id
        msg.tool_calls.each do |tc|
          input << { type: "function_call", id: tc.provider_id, call_id: tc.provider_fn_call_id, name: tc.function_name, arguments: tc.function_arguments }
          input << { type: "function_call_output", call_id: tc.provider_fn_call_id, output: tc.function_result }
        end
      end

      input
    end

    def build_available_tools(functions = [])
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

    def extract_content(response)
      response.dig("output").filter { |item| item.dig("type") == "message" }.map do |item|
        item.dig("content").map do |content|
          text = content.dig("text")
          refusal = content.dig("refusal")

          text || refusal
        end
      end.flatten.compact.join("\n")
    end

    def extract_tool_calls(response)
      response.dig("output").filter { |item| item.dig("type") == "function_call" }.map do |item|
        ToolCall::Function.new(
          provider_id: item.dig("id"),
          provider_fn_call_id: item.dig("call_id"),
          function_name: item.dig("name"),
          function_arguments: item.dig("arguments"),
        )
      end
    end
end
