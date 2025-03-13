require "test_helper"

class ChatTest < ActiveSupport::TestCase
  test "destroys chat" do
    chat = chats(:one)
    assert_difference("Message.count", -3) do
      chat.destroy
    end
  end
end
