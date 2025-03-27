require "test_helper"

class Provider::OpenaiTest < ActiveSupport::TestCase
  include LLMInterfaceTest

  setup do
    @subject = @openai = Provider::Openai.new(ENV.fetch("OPENAI_ACCESS_TOKEN", "test-openai-token"))
    @subject_model = "gpt-4o"
    @chat = chats(:two)
  end

  test "openai errors are automatically raised" do
    VCR.use_cassette("openai/chat/error") do
      response = @openai.chat_response(UserMessage.new(
        chat: @chat,
        content: "Error test",
        ai_model: "invalid-model-that-will-trigger-api-error"
      ))

      assert_not response.success?
      assert_kind_of Provider::Openai::Error, response.error
    end
  end

  test "basic chat response" do
    VCR.use_cassette("openai/chat/basic_response") do
      message = @chat.messages.create!(
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

  test "streams basic chat response" do
    VCR.use_cassette("openai/chat/basic_response") do
      collected_chunks = []

      mock_streamer = proc do |chunk|
        collected_chunks << chunk
      end

      message = @chat.messages.create!(
        type: "UserMessage",
        content: "This is a chat test.  If it's working, respond with a single word: Yes",
        ai_model: @subject_model
      )

      @subject.chat_response(message, streamer: mock_streamer)

      tool_call_chunks = collected_chunks.select { |chunk| chunk.type == "function_request" }
      text_chunks = collected_chunks.select { |chunk| chunk.type == "output_text" }
      response_chunks = collected_chunks.select { |chunk| chunk.type == "response" }

      assert_equal 1, text_chunks.size
      assert_equal 1, response_chunks.size
      assert_equal 0, tool_call_chunks.size
      assert_equal "Yes", text_chunks.first.data
      assert_equal "Yes", response_chunks.first.data.messages.first.content
    end
  end

  test "chat response with tool calls" do
    VCR.use_cassette("openai/chat/tool_calls") do
      response = @subject.chat_response(
        tool_call_message,
        instructions: "Use the tools available to you to answer the user's question.",
        available_functions: [ PredictableToolFunction.new(@chat) ]
      )

      assert response.success?
      assert_equal 1, response.data.functions.size
      assert_equal 1, response.data.messages.size
      assert_includes response.data.messages.first.content, PredictableToolFunction.expected_test_result
    end
  end

  test "streams chat response with tool calls" do
    VCR.use_cassette("openai/chat/tool_calls") do
      collected_chunks = []

      mock_streamer = proc do |chunk|
        collected_chunks << chunk
      end

      @subject.chat_response(
        tool_call_message,
        instructions: "Use the tools available to you to answer the user's question.",
        available_functions: [ PredictableToolFunction.new(@chat) ],
        streamer: mock_streamer
      )

      text_chunks = collected_chunks.select { |chunk| chunk.type == "output_text" }
      text_chunks = collected_chunks.select { |chunk| chunk.type == "output_text" }
      tool_call_chunks = collected_chunks.select { |chunk| chunk.type == "function_request" }
      response_chunks = collected_chunks.select { |chunk| chunk.type == "response" }

      assert_equal 1, tool_call_chunks.count
      assert text_chunks.count >= 1
      assert_equal 1, response_chunks.count

      assert_includes response_chunks.first.data.messages.first.content, PredictableToolFunction.expected_test_result
    end
  end

  private
    def tool_call_message
      UserMessage.new(chat: @chat, content: "What is my net worth?", ai_model: @subject_model)
    end

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
end
