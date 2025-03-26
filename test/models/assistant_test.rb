require "test_helper"

class AssistantTest < ActiveSupport::TestCase
  include ProviderTestHelper

  setup do
    @chat = chats(:two)
    @assistant = Assistant.for_chat(@chat)
    @provider = mock

    @assistant.expects(:get_model_provider).with("gpt-4o").returns(@provider)
  end

  test "responds to basic prompt without tools" do
    @provider.expects(:chat_response).returns(
      provider_success_response(
        Assistant::Provideable::ChatResponse.new(
          id: "1",
          model: "gpt-4o",
          messages: [
            Assistant::Provideable::ChatResponseMessage.new(
              id: "1",
              content: "Hello from assistant",
            )
          ],
          functions: []
        )
      )
    )

    assert_difference "Message.count", 1 do
      @assistant.respond_to(messages(:chat2_user))
    end
  end

  test "responds with tool function calls" do
    @provider.expects(:chat_response).returns(
      provider_success_response(
        Assistant::Provideable::ChatResponse.new(
          id: "1",
          model: "gpt-4o",
          messages: [
            Assistant::Provideable::ChatResponseMessage.new(
              id: "1",
              content: "Your net worth is $124,200",
            )
          ],
          functions: [
            Assistant::Provideable::ChatResponseFunctionExecution.new(
              id: "1",
              call_id: "1",
              name: "get_net_worth",
              arguments: "{}",
              result: "$124,200"
            )
          ]
        )
      )
    )

    assert_difference "Message.count", 1 do
      @assistant.respond_to(messages(:chat2_user))
    end

    message = @chat.messages.ordered.last
    assert_equal 1, message.tool_calls.size
  end
end
