require "test_helper"

class Provider::OpenaiTest < ActiveSupport::TestCase
  include LLMInterfaceTest

  setup do
    @subject = @openai = Provider::Openai.new(ENV.fetch("OPENAI_ACCESS_TOKEN", "test-openai-token"))
    @subject_model = "gpt-4o"
  end

  test "openai errors are automatically raised" do
    VCR.use_cassette("openai/chat/error") do
      response = @openai.chat_response("Test", model: "invalid-model-that-will-trigger-api-error")

      assert_not response.success?
      assert_kind_of Provider::Openai::Error, response.error
    end
  end

  test "basic chat response" do
    VCR.use_cassette("openai/chat/basic_response") do
      response = @subject.chat_response(
        "This is a chat test.  If it's working, respond with a single word: Yes",
        model: @subject_model
      )

      assert response.success?
      assert_equal 1, response.data.messages.size
      assert_includes response.data.messages.first.output_text, "Yes"
    end
  end

  test "streams basic chat response" do
    VCR.use_cassette("openai/chat/basic_streaming_response") do
      collected_chunks = []

      mock_streamer = proc do |chunk|
        collected_chunks << chunk
      end

      @subject.chat_response(
        "This is a chat test.  If it's working, respond with a single word: Yes",
        model: @subject_model,
        streamer: mock_streamer
      )

      text_chunks = collected_chunks.select { |chunk| chunk.type == "output_text" }
      response_chunks = collected_chunks.select { |chunk| chunk.type == "response" }

      assert_equal 1, text_chunks.size
      assert_equal 1, response_chunks.size
      assert_equal "Yes", text_chunks.first.data
      assert_equal "Yes", response_chunks.first.data.messages.first.output_text
    end
  end

  test "chat response with function calls" do
    VCR.use_cassette("openai/chat/function_calls") do
      first_response = @subject.chat_response(
        "What is my net worth?",
        model: @subject_model,
        instructions: "Use the tools available to you to answer the user's question.",
        functions: [ PredictableToolFunction.new.to_h ]
      )

      assert first_response.success?

      function_request = first_response.data.function_requests.first

      assert function_request.present?

      second_response = @subject.chat_response(
        "What is my net worth?",
        model: @subject_model,
        function_results: [
          {
            provider_id: function_request.id,
            provider_call_id: function_request.call_id,
            name: function_request.function_name,
            arguments: function_request.function_args,
            result: PredictableToolFunction.expected_test_result
          }
        ],
        previous_response_id: first_response.data.id
      )

      assert second_response.success?
      assert_equal 1, second_response.data.messages.size
      assert_includes second_response.data.messages.first.output_text, PredictableToolFunction.expected_test_result
    end
  end

  test "streams chat response with tool calls" do
    VCR.use_cassette("openai/chat/streaming_tool_calls", record: :all) do
      collected_chunks = []

      mock_streamer = proc do |chunk|
        collected_chunks << chunk
      end

      # Call #1: First streaming call, will return a function request
      @subject.chat_response(
        "What is my net worth?",
        model: @subject_model,
        instructions: "Use the tools available to you to answer the user's question.",
        functions: [ PredictableToolFunction.new.to_h ],
        streamer: mock_streamer
      )

      text_chunks = collected_chunks.select { |chunk| chunk.type == "output_text" }
      response_chunks = collected_chunks.select { |chunk| chunk.type == "response" }

      assert_equal 0, text_chunks.size
      assert_equal 1, response_chunks.size

      first_response = response_chunks.first.data
      function_request = first_response.function_requests.first

      # Reset collected chunks
      collected_chunks = []

      # Call #2: Second streaming call, will return a function result
      @subject.chat_response(
        "What is my net worth?",
        model: @subject_model,
        function_results: [
          {
            provider_id: function_request.id,
            provider_call_id: function_request.call_id,
            name: function_request.function_name,
            arguments: function_request.function_args,
            result: PredictableToolFunction.expected_test_result
          }
        ],
        previous_response_id: first_response.id,
        streamer: mock_streamer
      )

      text_chunks = collected_chunks.select { |chunk| chunk.type == "output_text" }
      response_chunks = collected_chunks.select { |chunk| chunk.type == "response" }

      assert text_chunks.size >= 1
      assert_equal 1, response_chunks.size

      assert_includes response_chunks.first.data.messages.first.output_text, PredictableToolFunction.expected_test_result
    end
  end

  private
    class PredictableToolFunction
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

      def to_h
        {
          name: self.class.name,
          description: self.class.description,
          params_schema:       {
            type: "object",
            properties: {},
            required: [],
            additionalProperties: false
          },
          strict: true
        }
      end
    end
end
