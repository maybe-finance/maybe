require "test_helper"

class MessageTest < ActiveSupport::TestCase
  setup do
    @chat = chats(:one)
  end

  test "broadcasts update and fetches open ai response after creation" do
    message = Message.create!(role: "user", chat: @chat, content: "Hello AI")

    # TODO: assert OpenAI call

    streams = capture_turbo_stream_broadcasts(@chat)

    assert_equal streams.size, 1
    assert_equal streams.first["action"], "append"
    assert_equal streams.first["target"], "messages"
  end
end
