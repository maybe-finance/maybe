require "test_helper"

class UserMessageTest < ActiveSupport::TestCase
  setup do
    @chat = chats(:one)
  end

  test "requests assistant response after creation" do
    @chat.expects(:ask_assistant_later).once

    message = UserMessage.create!(chat: @chat, content: "Hello from user", ai_model: "gpt-4.1")
    message.update!(content: "updated")

    streams = capture_turbo_stream_broadcasts(@chat)
    assert_equal 2, streams.size
    assert_equal "append", streams.first["action"]
    assert_equal "messages", streams.first["target"]
    assert_equal "update", streams.last["action"]
    assert_equal "user_message_#{message.id}", streams.last["target"]
  end
end
