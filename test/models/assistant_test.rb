require "test_helper"

class AssistantTest < ActiveSupport::TestCase
  include ProviderTestHelper

  setup do
    @chat = chats(:two)
    @assistant = Assistant.for_chat(@chat)
    @provider = mock
  end

  test "responds to basic prompt without tools" do
    @assistant.expects(:provider_for_model).with("gpt-4o").returns(@provider)
    @provider.expects(:chat_response).returns(
      provider_success_response(
        Assistant::Provideable::ChatResponse.new(
          message: Message.new(
            chat: @chat,
            role: "assistant",
            content: "Hello from assistant",
            ai_model: "gpt-4o"
          ),
          tool_calls: []
        )
      )
    )

    assert_difference "Message.count", 1 do
      @assistant.respond_to_user
    end
  end
end
