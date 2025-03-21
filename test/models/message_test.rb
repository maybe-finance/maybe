require "test_helper"

class MessageTest < ActiveSupport::TestCase
  setup do
    @chat = chats(:one)
  end

  test "user and assistant messages require an ai model" do
    message = Message.new(role: "internal", chat: @chat, content: "Hello")
    assert message.valid?

    message.role = "user"
    assert_not message.valid?

    message.role = "assistant"
    assert_not message.valid?

    message.ai_model = "openai-gpt-4o"
    assert message.valid?
  end

  test "conversation shows all messages in debug mode" do
    Chat.stubs(:debug_mode_enabled?).returns(true)

    assert_equal @chat.messages.count, @chat.messages.conversation.count
  end

  test "conversation shows only user and assistant messages in non-debug mode" do
    Chat.stubs(:debug_mode_enabled?).returns(false)

    assert_equal 3, @chat.messages.conversation.count
  end

  test "broadcasts append after creation and calls assistant to respond" do
    @chat.assistant.expects(:respond_to).once

    message = Message.create!(role: "user", chat: @chat, content: "Hello AI")

    streams = capture_turbo_stream_broadcasts(@chat)
    assert_equal streams.size, 1
    assert_equal streams.first["action"], "append"
    assert_equal streams.first["target"], "messages"
  end

  test "only user messages trigger assistant responses" do
    @chat.assistant.expects(:respond_to).never
    Message.create!(role: "assistant", chat: @chat, content: "Hello from AI")
  end

  test "broadcasts updates to a message" do
    message = messages(:assistant)

    @chat.assistant.expects(:respond_to).never

    message.update!(content: "Updated content")

    streams = capture_turbo_stream_broadcasts(@chat)
    assert_equal streams.size, 1
    assert_equal streams.first["action"], "update"
    assert_equal streams.first["target"], "message_#{message.id}"
  end
end
