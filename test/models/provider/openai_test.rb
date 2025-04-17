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
        { id: "3", name: "Netflix subscription", amount: 10, classification: "expense", merchant: "Netflix", hint: "Subscriptions" },
        { id: "4", name: "paycheck", amount: 3000, classification: "income" },
        { id: "5", name: "Italian dinner with friends", amount: 100, classification: "expense" },
        { id: "6", name: "1212XXXBCaaa charge", amount: 2.99, classification: "expense" }
      ]

      response = @subject.auto_categorize(
        transactions: input_transactions,
        user_categories: [
          { id: "shopping_id", name: "Shopping", is_subcategory: false, parent_id: nil, classification: "expense" },
          { id: "subscriptions_id", name: "Subscriptions", is_subcategory: true, parent_id: nil, classification: "expense" },
          { id: "restaurants_id", name: "Restaurants", is_subcategory: false, parent_id: nil, classification: "expense" },
          { id: "fast_food_id", name: "Fast Food", is_subcategory: true, parent_id: "restaurants_id", classification: "expense" },
          { id: "income_id", name: "Income", is_subcategory: false, parent_id: nil, classification: "income" }
        ]
      )

      assert response.success?
      assert_equal input_transactions.size, response.data.size

      txn1 = response.data.find { |c| c.transaction_id == "1" }
      txn2 = response.data.find { |c| c.transaction_id == "2" }
      txn3 = response.data.find { |c| c.transaction_id == "3" }
      txn4 = response.data.find { |c| c.transaction_id == "4" }
      txn5 = response.data.find { |c| c.transaction_id == "5" }
      txn6 = response.data.find { |c| c.transaction_id == "6" }

      assert_equal "Fast Food", txn1.category_name
      assert_equal "Shopping", txn2.category_name
      assert_equal "Subscriptions", txn3.category_name
      assert_equal "Income", txn4.category_name
      assert_equal "Restaurants", txn5.category_name
      assert_nil txn6.category_name
    end
  end

  test "auto detects merchants" do
    VCR.use_cassette("openai/auto_detect_merchants") do
      input_transactions = [
        { id: "1", name: "McDonalds", amount: 20, classification: "expense" },
        { id: "2", name: "local pub", amount: 20, classification: "expense" },
        { id: "3", name: "WMT purchases", amount: 20, classification: "expense" },
        { id: "4", name: "amzn 123 abc", amount: 20, classification: "expense" },
        { id: "5", name: "chaseX1231", amount: 2000, classification: "income" },
        { id: "6", name: "check deposit 022", amount: 200, classification: "income" },
        { id: "7", name: "shooters bar and grill", amount: 200, classification: "expense" },
        { id: "8", name: "Microsoft Office subscription", amount: 200, classification: "expense" }
      ]

      response = @subject.auto_detect_merchants(
        transactions: input_transactions,
        user_merchants: [ { name: "Shooters" } ]
      )

      assert response.success?
      assert_equal input_transactions.size, response.data.size

      txn1 = response.data.find { |c| c.transaction_id == "1" }
      txn2 = response.data.find { |c| c.transaction_id == "2" }
      txn3 = response.data.find { |c| c.transaction_id == "3" }
      txn4 = response.data.find { |c| c.transaction_id == "4" }
      txn5 = response.data.find { |c| c.transaction_id == "5" }
      txn6 = response.data.find { |c| c.transaction_id == "6" }
      txn7 = response.data.find { |c| c.transaction_id == "7" }
      txn8 = response.data.find { |c| c.transaction_id == "8" }

      assert_equal "McDonald's", txn1.business_name
      assert_equal "mcdonalds.com", txn1.business_url

      assert_nil txn2.business_name
      assert_nil txn2.business_url

      assert_equal "Walmart", txn3.business_name
      assert_equal "walmart.com", txn3.business_url

      assert_equal "Amazon", txn4.business_name
      assert_equal "amazon.com", txn4.business_url

      assert_nil txn5.business_name
      assert_nil txn5.business_url

      assert_nil txn6.business_name
      assert_nil txn6.business_url

      assert_equal "Shooters", txn7.business_name
      assert_nil txn7.business_url

      assert_equal "Microsoft", txn8.business_name
      assert_equal "microsoft.com", txn8.business_url
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
