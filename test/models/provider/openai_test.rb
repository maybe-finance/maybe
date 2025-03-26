require "test_helper"

class Provider::OpenaiTest < ActiveSupport::TestCase
  include LLMInterfaceTest

  setup do
    @subject = @openai = Provider::Openai.new(ENV.fetch("OPENAI_ACCESS_TOKEN", "test-openai-token"))
    @subject_model = "gpt-4o"
  end

  test "openai errors are automatically raised" do
    VCR.use_cassette("openai/chat/error") do
      chat = chats(:two)

      response = @openai.chat_response(UserMessage.new(
        chat: chat,
        content: "Error test",
        ai_model: "invalid-model-that-will-trigger-api-error"
      ))

      assert_not response.success?
      assert_kind_of Provider::Openai::Error, response.error
    end
  end

  test "provides basic chat response 2" do
    VCR.use_cassette("openai/chat/basic_response", record: :all) do
      chat = chats(:two)
      message = chat.messages.create!(
        type: "UserMessage",
        content: "This is a chat test.  If it's working, respond with a single word: Yes",
        ai_model: @subject_model
      )

      response = @subject.chat_response(message)

      assert response.success?
      assert_equal 1, response.data.messages.size
      assert_includes response.data.messages.first.content, "Yes"
    end
  end

  test "handles chat response with tool calls" do
    VCR.use_cassette("openai/chat/tool_calls", record: :all) do
      class PredictableToolFunction < Assistant::Function
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

      chat = chats(:two)
      initial_message = UserMessage.new(chat: chat, content: "What is my net worth?", ai_model: @subject_model)

      response = @openai.chat_response(
        initial_message,
        instructions: "Use the tools available to you to answer the user's question.",
        available_functions: [ PredictableToolFunction.new(chat) ]
      )

      assert response.success?
      assert_equal 1, response.data.functions.size
      assert_equal 1, response.data.messages.size
      assert_includes response.data.messages.first.content, PredictableToolFunction.expected_test_result
    end
  end
end
