require "test_helper"

module LLMInterfaceTest
  extend ActiveSupport::Testing::Declarative

  test "provides basic chat response" do
    VCR.use_cassette("#{vcr_key_prefix}/chat/basic_response") do
      response = @subject.chat_response(
        model: @subject_model,
        chat_history: [
          UserMessage.new(
            content: "This is a chat test.  If it's working, respond with a single word: Yes",
            ai_model: @subject_model
          )
        ]
      )

      assert response.success?
      assert_equal 1, response.data.messages.size
      assert_includes response.data.messages.first.content, "Yes"
    end
  end

  private
    def vcr_key_prefix
      @subject.class.name.demodulize.underscore
    end
end
