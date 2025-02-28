require "application_system_test_case"

class ChatsTest < ApplicationSystemTestCase
  setup do
    @user = users(:family_admin)
    login_as(@user)
  end

  test "can navigate to chats index" do
    # Navigate to chats index
    visit chats_path
    assert_selector "h1", text: "All Chats"

    # Verify the New Chat button exists
    assert_selector "a", text: "New Chat"
  end

  test "can create a new chat" do
    visit chats_path
    click_on "New Chat"

    # After creating a new chat, we should be redirected to the root path with the chat_id parameter
    # The format parameter may also be present, so we'll check the path without the query string
    assert_match(/^\/$/, current_path)

    # Verify we can see the chat title
    assert_selector "h1", text: "New Chat"
  end

  test "can navigate to chats and view example questions" do
    # Navigate to chats index
    visit chats_path
    assert_selector "h1", text: "All Chats"

    # Create a new chat
    click_on "New Chat"

    # First chat will be empty and should show example questions
    within "#chat-container" do
      assert_selector "button", text: "What's my current net worth?"
      assert_selector "button", text: "How much did I spend on groceries last month?"
      assert_selector "button", text: "What's my savings rate this year?"
      assert_selector "button", text: "How has my spending changed compared to last month?"
    end
  end

  test "can click example question to fill chat form" do
    # Create a new chat directly
    visit chats_path
    click_on "New Chat"

    # Click an example question
    within "#chat-container" do
      find("button", text: "What's my current net worth?").click
    end

    # Verify the textarea has been filled with the question
    assert_field "message[content]", with: "What's my current net worth?"
  end
end
