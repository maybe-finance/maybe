require "test_helper"

class ChatTest < ActiveSupport::TestCase
  test "should not save chat without title" do
    chat = Chat.new(user: users(:family_admin), family: families(:dylan_family))
    assert_not chat.save, "Saved the chat without a title"
  end

  test "should save valid chat" do
    chat = Chat.new(title: "Test Chat", user: users(:family_admin), family: families(:dylan_family))
    assert chat.save, "Could not save valid chat"
  end

  test "should destroy associated messages when chat is destroyed" do
    chat = chats(:one)
    assert_difference("Message.count", -4) do
      chat.destroy
    end
  end
end
