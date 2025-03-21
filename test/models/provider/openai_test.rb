require "test_helper"

class Provider::OpenAITest < ActiveSupport::TestCase
  include LLMInterfaceTest

  setup do
    @subject = @openai = Provider::OpenAI.new(ENV.fetch("OPENAI_ACCESS_TOKEN"))
    @subject_model = "gpt-4o"
  end

  test "openai errors are automatically raised" do
    VCR.use_cassette("open_ai/chat/error") do
      response = @openai.chat_response(
        model: "invalid-model-key",
        messages: [ Message.new(role: "user", content: "Error test") ]
      )

      assert_not response.success?
      assert_kind_of Faraday::BadRequestError, response.error

      # Adheres to openai response schema
      assert_equal "model_not_found", response.error.response[:body].dig("error", "code")
    end
  end

  test "handles chat response with tool calls" do
    VCR.use_cassette("open_ai/chat/tool_calls", record: :all) do
      class PredictableToolFunction
        include Assistant::Functions::Toolable

        class << self
          def name
            "get_net_worth"
          end

          def description
            "Gets user net worth data"
          end
        end

        def call(params = {})
          "$124,200"
        end
      end

      initial_message = Message.new(role: "user", content: "What is my net worth?")

      response = @openai.chat_response(
        model: "gpt-4o",
        instructions: Assistant.instructions,
        functions: [ PredictableToolFunction ],
        messages: [ initial_message ]
      )

      assert response.success?
      assert response.data.tool_calls.size == 1

      tool_call = response.data.tool_calls.first
      tool_call_result = PredictableToolFunction.new.call(JSON.parse(tool_call.function_arguments))

      message_with_tool_calls = Message.new(
        role: "assistant",
        status: "pending",
        content: "",
        tool_calls: [
          ToolCall::Function.new(
            provider_id: tool_call.provider_id,
            provider_fn_call_id: tool_call.provider_fn_call_id,
            function_name: tool_call.function_name,
            function_arguments: tool_call.function_arguments,
            function_result: tool_call_result
          )
        ]
      )

      second_response = @openai.chat_response(
        model: "gpt-4o",
        instructions: Assistant.instructions,
        messages: [ initial_message, message_with_tool_calls ]
      )

      assert second_response.success?
      assert second_response.data.message.complete?
      assert second_response.data.message.content.include?(tool_call_result) # Somewhere in the response should be the tool call result value
    end
  end
end
