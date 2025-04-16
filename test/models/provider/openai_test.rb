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

  test "auto categorizes transactions by various attributes" do
    VCR.use_cassette("openai/auto_categorize") do
      input_transactions = [
        { id: "1", name: "McDonalds", amount: 20, classification: "expense", merchant: "McDonalds", hint: "Fast Food" },
        { id: "2", name: "Amazon purchase", amount: 100, classification: "expense", merchant: "Amazon" },
        { id: "3", name: "Netflix subscription", amount: 10, classification: "expense", merchant: "Netflix", hint: "Subscriptions" }
      ]

      response = @subject.auto_categorize(
        transactions: input_transactions,
        user_categories: [
          { id: "shopping_id", name: "Shopping", is_subcategory: false, parent_id: nil, classification: "expense" },
          { id: "restaurants_id", name: "Restaurants", is_subcategory: false, parent_id: nil, classification: "expense" }
        ]
      )

      assert response.success?
      assert_equal input_transactions.size, response.data.size

      txn1 = response.data.find { |c| c.transaction_id == "1" }
      txn2 = response.data.find { |c| c.transaction_id == "2" }
      txn3 = response.data.find { |c| c.transaction_id == "3" }

      assert_equal "Restaurants", txn1.category_name
      assert_equal "Shopping", txn2.category_name
      assert_nil txn3.category_name
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

      response = @subject.chat_response(
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
      assert_equal response_chunks.first.data, response.data
    end
  end

  test "chat response with function calls" do
    VCR.use_cassette("openai/chat/function_calls") do
      prompt = "What is my net worth?"

      functions = [
        {
          name: "get_net_worth",
          description: "Gets a user's net worth",
          params_schema: { type: "object", properties: {}, required: [], additionalProperties: false },
          strict: true
        }
      ]

      first_response = @subject.chat_response(
        prompt,
        model: @subject_model,
        instructions: "Use the tools available to you to answer the user's question.",
        functions: functions
      )

      assert first_response.success?

      function_request = first_response.data.function_requests.first

      assert function_request.present?

      second_response = @subject.chat_response(
        prompt,
        model: @subject_model,
        function_results: [ {
          call_id: function_request.call_id,
          output: { amount: 10000, currency: "USD" }.to_json
        } ],
        previous_response_id: first_response.data.id
      )

      assert second_response.success?
      assert_equal 1, second_response.data.messages.size
      assert_includes second_response.data.messages.first.output_text, "$10,000"
    end
  end

  test "streams chat response with function calls" do
    VCR.use_cassette("openai/chat/streaming_function_calls") do
      collected_chunks = []

      mock_streamer = proc do |chunk|
        collected_chunks << chunk
      end

      prompt = "What is my net worth?"

      functions = [
        {
          name: "get_net_worth",
          description: "Gets a user's net worth",
          params_schema: { type: "object", properties: {}, required: [], additionalProperties: false },
          strict: true
        }
      ]

      # Call #1: First streaming call, will return a function request
      @subject.chat_response(
        prompt,
        model: @subject_model,
        instructions: "Use the tools available to you to answer the user's question.",
        functions: functions,
        streamer: mock_streamer
      )

      text_chunks = collected_chunks.select { |chunk| chunk.type == "output_text" }
      response_chunks = collected_chunks.select { |chunk| chunk.type == "response" }

      assert_equal 0, text_chunks.size
      assert_equal 1, response_chunks.size

      first_response = response_chunks.first.data
      function_request = first_response.function_requests.first

      # Reset collected chunks for the second call
      collected_chunks = []

      # Call #2: Second streaming call, will return a function result
      @subject.chat_response(
        prompt,
        model: @subject_model,
        function_results: [
          {
            call_id: function_request.call_id,
            output: { amount: 10000, currency: "USD" }
          }
        ],
        previous_response_id: first_response.id,
        streamer: mock_streamer
      )

      text_chunks = collected_chunks.select { |chunk| chunk.type == "output_text" }
      response_chunks = collected_chunks.select { |chunk| chunk.type == "response" }

      assert text_chunks.size >= 1
      assert_equal 1, response_chunks.size

      assert_includes response_chunks.first.data.messages.first.output_text, "$10,000"
    end
  end
end
