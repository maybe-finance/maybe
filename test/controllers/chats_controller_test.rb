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

    # Verify the system message was created
    assert_equal 1, chat.messages.developer.count
  end

  test "should show chat" do
    chat = Chat.create!(user: @user, title: "Test Chat")

    get chat_url(chat)
    assert_response :success
  end

  test "should destroy chat" do
    chat = Chat.create!(user: @user, title: "Test Chat")

    assert_difference("Chat.count", -1) do
      delete chat_url(chat)
    end

    assert_redirected_to chats_url
  end

  test "should not allow access to other user's chats" do
    other_user = users(:family_member)
    other_chat = Chat.create!(user: other_user, title: "Other User's Chat")

    get chat_url(other_chat)
    assert_response :not_found

    delete chat_url(other_chat)
    assert_response :not_found
  end
end
