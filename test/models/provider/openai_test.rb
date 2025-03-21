require "test_helper"

class Provider::OpenAITest < ActiveSupport::TestCase
  setup do
    @openai = Provider::OpenAI.new(ENV.fetch("OPENAI_ACCESS_TOKEN"))
  end

  test "provides basic chat response" do
    VCR.use_cassette("openai/chat/basic_response") do
      response = @openai.fetch_chat_response({
        model: "gpt-4o-2024-08-06",
        input: [
          { role: "user", content: "This is a chat test.  Can you confirm it worked?", type: "message" }
        ]
      })

      assert response.success?
      assert response.data.messages.size > 0
      assert_equal "gpt-4o-2024-08-06", response.data.messages.first.ai_model
      assert_kind_of String, response.data.messages.first.content
    end
  end
end
