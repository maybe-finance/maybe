require "test_helper"

class ChatTest < ActiveSupport::TestCase
  setup do
    @user = users(:family_admin)
    @assistant = mock
  end

  test "user sees all messages in debug mode" do
    chat = chats(:one)
    with_env_overrides AI_DEBUG_MODE: "true" do
      assert_equal chat.messages.count, chat.conversation_messages.count
    end
  end

  test "user sees assistant and user messages in normal mode" do
    chat = chats(:one)
    assert_equal 3, chat.conversation_messages.count
  end

  test "creates with initial message" do
    prompt = "Test prompt"

    assert_difference "@user.chats.count", 1 do
      chat = @user.chats.start!(prompt, model: "gpt-4.1")

      assert_equal 1, chat.messages.count
      assert_equal 1, chat.messages.where(type: "UserMessage").count
    end
  end
end
