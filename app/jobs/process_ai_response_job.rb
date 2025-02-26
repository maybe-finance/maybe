class ProcessAiResponseJob < ApplicationJob
  queue_as :default

  def perform(chat_id, message_id)
    chat = Chat.find(chat_id)
    user_message = Message.find(message_id)

    # Update chat title if it's the first user message
    if chat.title == "New Chat" && chat.messages.where(role: "user").count == 1
      new_title = user_message.content.truncate(30)
      chat.update(title: new_title)
    end

    # Simulate AI thinking time
    sleep(2)

    # Create AI response
    ai_response = chat.messages.create!(
      role: "assistant",
      content: generate_response(user_message.content)
    )

    # Broadcast the response to the chat channel
    Turbo::StreamsChannel.broadcast_append_to(
      chat,
      target: "messages",
      partial: "messages/message",
      locals: { message: ai_response }
    )

    # Hide the thinking indicator
    Turbo::StreamsChannel.broadcast_replace_to(
      chat,
      target: "thinking",
      html: '<div id="thinking" class="hidden"></div>'
    )
  end

  private

    def generate_response(user_message)
      # This is a placeholder for actual AI integration
      responses = [
        "Based on your financial data, I'd recommend setting aside 20% of your income for savings and investments.",
        "Looking at your spending patterns, you might want to consider reducing expenses in the dining category.",
        "Your investment portfolio is well-diversified, but you might want to consider increasing your exposure to international markets.",
        "I notice you have some high-interest debt. Prioritizing paying that off could save you money in the long run.",
        "Your emergency fund looks good! The recommended amount is 3-6 months of expenses, and you're right in that range.",
        "Based on your goals, you're on track for retirement at your target age. Keep up the good work!",
        "I've analyzed your transactions and found a few potential subscriptions you might not be using regularly.",
        "Your tax withholding seems a bit high. You might want to adjust it to have more cash flow throughout the year.",
        "I've noticed some unusual spending patterns this month compared to your historical data. Would you like me to break that down for you?",
        "Based on your income and spending habits, you could potentially increase your investment contributions by about 5%."
      ]

      # Return a response based on the user message or a random one if no match
      if user_message.downcase.include?("investment")
        "Looking at your investment portfolio, you have a good mix of stocks and bonds. Your current allocation is 60% stocks and 40% bonds, which is appropriate for your risk tolerance. Your returns over the past year have been about 7%, which is slightly above the market average."
      elsif user_message.downcase.include?("budget")
        "Based on your spending patterns, you're currently allocating about 35% to housing, 15% to transportation, 20% to food, and 30% to other expenses. This is generally in line with recommended budgeting guidelines, though you might be able to reduce your food expenses by about 5%."
      elsif user_message.downcase.include?("save") || user_message.downcase.include?("saving")
        "You're currently saving about 10% of your income. Financial experts typically recommend saving 15-20% of your income. If you could increase your savings rate by just 2%, you'd be on track to reach your retirement goals 3 years earlier."
      elsif user_message.downcase.include?("debt")
        "You currently have $15,000 in student loans at 4.5% interest and $3,000 in credit card debt at 18% interest. I'd recommend focusing on paying off the high-interest credit card debt first, which could save you approximately $540 in interest over the next year."
      else
        responses.sample
      end
    end
end
