require "test_helper"

class MessageTest < ActiveSupport::TestCase
  test "should not save message without content" do
    message = Message.new(role: "user", chat: chats(:one), user: users(:family_admin))
    assert_not message.save, "Saved the message without content"
  end

  test "should not save message without role" do
    message = Message.new(content: "Test message", chat: chats(:one), user: users(:family_admin))
    assert_not message.save, "Saved the message without role"
  end

  test "should save valid user message" do
    message = Message.new(content: "Test message", role: "user", chat: chats(:one), user: users(:family_admin))
    assert message.save, "Could not save valid user message"
  end

  test "should save valid assistant message without user" do
    message = Message.new(content: "Test response", role: "assistant", chat: chats(:one))
    assert message.save, "Could not save valid assistant message"
  end
end
