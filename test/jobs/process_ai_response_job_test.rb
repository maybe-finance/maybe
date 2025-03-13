require "test_helper"

class ProcessAiResponseJobTest < ActiveJob::TestCase
  test "generates a response using FinancialAssistant" do
    # Create a test user and chat
    user = users(:family_admin)
    chat = Chat.create!(user: user, title: "Test Chat")

    # Create a system message
    system_message = chat.messages.create!(
      role: "developer",
      content: "You are a helpful financial assistant.",
    )

    # Create a user message
    user_message = chat.messages.create!(
      role: "user",
      content: "What is my net worth?",
    )

    # Mock the FinancialAssistant class
    mock_assistant = mock
    mock_assistant.expects(:with_chat).with(chat).returns(mock_assistant)
    mock_assistant.expects(:query).with("What is my net worth?", chat.messages).returns("Your net worth is $100,000.")
    Ai::FinancialAssistant.expects(:new).with(user.family).returns(mock_assistant)

    # Run the job
    assert_difference "Message.count", 1 do
      ProcessAiResponseJob.perform_now(chat.id, user_message.id)
    end

    # Check the created message (should be the only assistant message)
    response_message = chat.messages.where(role: "assistant").last
    assert_not_nil response_message
    assert_equal "assistant", response_message.role
    assert_equal "Your net worth is $100,000.", response_message.content
    assert_equal chat, response_message.chat
  end

  test "handles errors gracefully" do
    # Create a test user and chat
    user = users(:family_admin)
    chat = Chat.create!(user: user, title: "Test Chat")

    # Create a user message
    user_message = chat.messages.create!(
      role: "user",
      content: "What is my net worth?",
    )

    # Mock the FinancialAssistant to raise an error
    mock_assistant = mock
    mock_assistant.expects(:with_chat).with(chat).returns(mock_assistant)
    mock_assistant.expects(:query).raises(StandardError.new("Test error"))
    Ai::FinancialAssistant.expects(:new).with(user.family).returns(mock_assistant)

    # Run the job
    assert_difference "Message.count", 1 do
      ProcessAiResponseJob.perform_now(chat.id, user_message.id)
    end

    # Check the created message contains an error message (should be the only assistant message)
    response_message = chat.messages.where(role: "assistant").last
    assert_not_nil response_message
    assert_equal "assistant", response_message.role
    assert_match /I'm sorry, I encountered an error/, response_message.content
  end
end
