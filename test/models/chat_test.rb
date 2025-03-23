require "test_helper"

class ChatTest < ActiveSupport::TestCase
  setup do
    @user = users(:family_admin)
    @assistant = mock
  end

  test "creates with initial message" do
    prompt = "Test prompt"

    assert_difference "@user.chats.count", 1 do
      chat = @user.chats.create_from_prompt!(prompt)

      assert_equal 1, chat.messages.count
      assert_equal 1, chat.messages.user.count
    end
  end
end
