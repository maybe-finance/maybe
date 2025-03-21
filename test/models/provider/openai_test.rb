require "test_helper"

class Provider::OpenAITest < ActiveSupport::TestCase
  include LLMInterfaceTest

  setup do
    @subject = @openai = Provider::OpenAI.new(ENV.fetch("OPENAI_ACCESS_TOKEN"))
  end

  test "verifies model support" do
    assert_not @subject.supports_model?("unknown-for-test-that-returns-false")
  end

  test "provides basic chat response" do
    VCR.use_cassette("#{vcr_key_prefix}/chat/basic_response") do
      response = @subject.chat_response(
        model: "gpt-4o",
        messages: [
          Message.new(
            role: "user",
            content: "This is a chat test.  If it's working, respond with a single word: Yes"
          )
        ]
      )

      assert response.success?
      assert response.data.messages.size > 0
      assert_equal "gpt-4o-2024-08-06", response.data.messages.first.ai_model
      assert_equal "Yes", response.data.messages.first.content
    end
  end

  test "provides response with tool calls" do
    VCR.use_cassette("#{vcr_key_prefix}/chat/tool_calls") do
      # A prompt that should use multiple tools
      prompt = <<~PROMPT
        Can you show me a breakdown of the following?

        - My net worth over the last 30 days
        - My income over the last 30 days
        - My spending over the last 30 days
      PROMPT

      response = @subject.chat_response(
        model: "gpt-4o",
        instructions: Assistant.instructions,
        functions: Assistant.available_functions,
        messages: [
          Message.new(role: "user", content: prompt)
        ]
      )

      assert response.success?
    end
  end

  private
    def vcr_key_prefix
      @subject.class.name.demodulize.underscore
    end
end
