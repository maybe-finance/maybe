require "test_helper"

class AssistantMessageTest < ActiveSupport::TestCase
  setup do
    @chat = chats(:one)
  end

  test "broadcasts append after creation" do
    message = AssistantMessage.create!(chat: @chat, content: "Hello from assistant", ai_model: "gpt-4.1")
    message.update!(content: "updated")

    streams = capture_turbo_stream_broadcasts(@chat)
    assert_equal 2, streams.size
    assert_equal "append", streams.first["action"]
    assert_equal "messages", streams.first["target"]
    assert_equal "update", streams.last["action"]
    assert_equal "assistant_message_#{message.id}", streams.last["target"]
  end
end
