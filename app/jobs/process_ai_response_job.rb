class ProcessAiResponseJob < ApplicationJob
  queue_as :default

  def perform(chat_id, message_id)
    chat = Chat.find(chat_id)
    user_message = Message.find(message_id)

    # Debug mode: Log the start of processing
    Ai::DebugMode.log_to_chat(chat, "🐞 DEBUG: Starting to process user query")

    # Update chat title if it's the first user message
    if chat.title == "New Chat" && chat.messages.where(role: "user").count == 1
      new_title = user_message.content.truncate(30)
      chat.update(title: new_title)
    end

    # Create "thinking" indicator
    Turbo::StreamsChannel.broadcast_replace_to(
      chat,
      target: "thinking",
      html: '<div id="thinking" class="py-2 px-4"><div class="flex items-center"><div class="typing-indicator"></div></div></div>'
    )

    # Create AI response
    ai_response = chat.messages.create!(
      role: "assistant",
      content: generate_response(chat, user_message.content)
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

    # Debug mode: Log completion
    Ai::DebugMode.log_to_chat(chat, "🐞 DEBUG: Processing completed")
  end

  private

    def generate_response(chat, user_message)
      # Use our financial assistant for responses
      begin
        # Get the system message for context
        system_message = chat.messages.find_by(role: "system")&.content

        # Create a financial assistant for the user's family
        family = chat.user.family
        financial_assistant = Ai::FinancialAssistant.new(family).with_chat(chat)

        # Log family information
        Ai::DebugMode.log_to_chat(
          chat,
          "🐞 DEBUG: Using family data",
          {
            family_id: family.id,
            currency: family.currency
          }
        )

        # Process the query and get a response
        response = financial_assistant.query(user_message)

        response
      rescue => e
        error_message = "Error generating AI response: #{e.message}"
        Rails.logger.error(error_message)
        Rails.logger.error(e.backtrace.join("\n"))

        # Debug mode: Log error details
        Ai::DebugMode.log_to_chat(
          chat,
          "🐞 DEBUG: Error encountered",
          {
            error: e.message,
            backtrace: e.backtrace.first(5)
          }
        )

        "I'm sorry, I encountered an error while processing your request. Please try again later."
      end
    end
end
