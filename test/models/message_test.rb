require "test_helper"

class MessageTest < ActiveSupport::TestCase
  setup do
    @chat = chats(:one)
  end

  test "user and assistant messages require an ai model" do
    message = Message.new(role: "developer", chat: @chat, content: "Hello")
    assert message.valid?

    message.role = "user"
    assert_not message.valid?

    message.role = "assistant"
    assert_not message.valid?

    message.ai_model = "openai-gpt-4o"
    assert message.valid?
  end

  test "broadcasts append after creation and calls assistant to respond" do
    @chat.expects(:ask_assistant_later).once

    message = Message.create!(role: "user", chat: @chat, content: "Hello AI", ai_model: "gpt-4o")

    streams = capture_turbo_stream_broadcasts(@chat)
    assert_equal streams.size, 1
    assert_equal streams.first["action"], "append"
    assert_equal streams.first["target"], "messages"
  end

  test "only user messages trigger assistant responses" do
    @chat.expects(:ask_assistant_later).never
    Message.create!(role: "assistant", chat: @chat, content: "Hello from AI", ai_model: "gpt-4o")
  end

  test "broadcasts updates to a message" do
    message = messages(:assistant)

    @chat.expects(:ask_assistant_later).never

    message.update!(content: "Updated content")

    streams = capture_turbo_stream_broadcasts(@chat)
    assert_equal streams.size, 1
    assert_equal streams.first["action"], "update"
    assert_equal streams.first["target"], "message_#{message.id}"
  end
end
