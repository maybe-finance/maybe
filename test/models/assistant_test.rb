require "test_helper"

class AssistantTest < ActiveSupport::TestCase
  include ProviderTestHelper

  setup do
    @chat = chats(:two)
    @assistant = Assistant.for_chat(@chat)
    @provider = mock
  end

  test "responds to basic prompt without tools" do
    @assistant.expects(:provider_for_model).with("gpt-4o").returns(@provider).twice
    @provider.expects(:chat_response).returns(
      provider_success_response(
        Assistant::Provideable::ChatResponse.new(
          messages: [
            Assistant::Provideable::ChatResponseMessage.new(
              id: "1",
              content: "Hello from assistant"
            )
          ],
          functions: []
        )
      )
    )

    assert_difference "Message.count", 1 do
      @assistant.respond
    end
  end
end
