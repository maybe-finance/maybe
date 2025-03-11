require "test_helper"

class ChatsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:family_admin)
    @family = families(:dylan_family)
    sign_in @user
  end

  test "should get index" do
    get chats_url
    assert_response :success
  end

  test "should create chat with proper system message" do
    assert_difference("Chat.count") do
      post chats_url
    end

    chat = Chat.last

    # Check that we're redirected to the root path with a chat_id parameter
    assert_redirected_to %r{^http://www.example.com/\?chat_id=.+$}

    # Verify the system message was created
    system_message = chat.messages.find_by(role: "system")
    assert_not_nil system_message
    assert system_message.internal?

    # Just verify that a system message exists with some content
    assert system_message.content.present?
  end

  test "should show chat" do
    chat = Chat.create!(user: @user, title: "Test Chat", family: @family)

    get chat_url(chat)
    assert_response :success
  end

  test "should destroy chat" do
    chat = Chat.create!(user: @user, title: "Test Chat", family: @family)

    assert_difference("Chat.count", -1) do
      delete chat_url(chat)
    end

    assert_redirected_to chats_url
  end

  test "should not allow access to other user's chats" do
    other_user = users(:family_member)
    other_chat = Chat.create!(user: other_user, title: "Other User's Chat", family: @family)

    get chat_url(other_chat)
    assert_response :not_found

    delete chat_url(other_chat)
    assert_response :not_found
  end

  test "should clear chat" do
    chat = Chat.create!(user: @user, title: "Test Chat", family: @family)
    system_message = chat.messages.create!(role: "system", content: "System prompt", internal: true)
    user_message = chat.messages.create!(role: "user", content: "User message", user: @user)

    post clear_chat_url(chat)

    # Check that we're redirected to the root path with a chat_id parameter
    assert_redirected_to %r{^http://www.example.com/\?chat_id=.+$}

    # System message should remain, user message should be deleted
    assert_equal 1, chat.messages.count
    assert chat.messages.exists?(id: system_message.id)
    assert_not chat.messages.exists?(id: user_message.id)
  end
end
