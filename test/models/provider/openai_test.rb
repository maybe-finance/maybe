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
        chat_history: [ UserMessage.new(content: "Error test") ]
      )

      assert_not response.success?
      assert_kind_of Faraday::BadRequestError, response.error

      # Adheres to openai response schema
      assert_equal "model_not_found", response.error.response[:body].dig("error", "code")
    end
  end

  test "handles chat response with tool calls" do
    VCR.use_cassette("open_ai/chat/tool_calls") do
      class PredictableToolFunction
        include Assistant::Functions::Toolable

        class << self
          def expected_test_result
            "$124,200"
          end

          def name
            "get_net_worth"
          end

          def description
            "Gets user net worth data"
          end
        end

        def call(params = {})
          self.class.expected_test_result
        end
      end

      initial_message = UserMessage.new(content: "What is my net worth?")

      response = @openai.chat_response(
        model: "gpt-4o",
        instructions: "Use the tools available to you to answer the user's question.",
        functions: [ PredictableToolFunction.new ],
        chat_history: [ initial_message ]
      )

      assert response.success?
      assert_equal 1, response.data.functions.size
      assert_equal 1, response.data.messages.size
      assert_includes response.data.messages.first.content, PredictableToolFunction.expected_test_result
    end
  end
end
