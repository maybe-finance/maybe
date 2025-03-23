require "test_helper"

module LLMInterfaceTest
  extend ActiveSupport::Testing::Declarative

  test "provides basic chat response" do
    skip
    VCR.use_cassette("#{vcr_key_prefix}/chat/basic_response") do
      response = @subject.chat_response(
        model: @subject_model,
        messages: [
          Message.new(
            role: "user",
            content: "This is a chat test.  If it's working, respond with a single word: Yes"
          )
        ]
      )

      assert response.success?
      assert_includes response.data.message.ai_model, @subject_model
      assert_equal "Yes", response.data.message.content
    end
  end

  private
    def vcr_key_prefix
      @subject.class.name.demodulize.underscore
    end
end
