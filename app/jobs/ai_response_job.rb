class AiResponseJob < ApplicationJob
  queue_as :default

  def perform(chat_id, user_message_id)
    chat = Chat.find_by(id: chat_id)
    user_message = Message.find_by(id: user_message_id)

    return unless chat && user_message

    # In a real implementation, this would call an AI service
    # For now, we'll just create a simulated response with a delay

    # Simulate processing time
    sleep(1)

    # Create AI response
    chat.messages.create(
      content: generate_ai_response(user_message.content),
      role: "assistant"
    )
  end

  private

    def generate_ai_response(user_message)
      # This is a stub - in a real implementation, this would call an AI service
      responses = [
        "That's a great question about your finances. Based on your current situation, I would recommend reviewing your budget allocations.",
        "Looking at your financial data, I can see that you've been making progress toward your savings goals. Keep it up!",
        "I've analyzed your spending patterns, and it seems like there might be opportunities to reduce expenses in a few categories.",
        "Based on your investment portfolio, you might want to consider diversifying a bit more to reduce risk.",
        "Your financial health score is looking good! You've made some smart decisions with your money recently."
      ]

      responses.sample
    end
end
