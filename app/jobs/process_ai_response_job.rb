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

    # Show initial thinking indicator - use replace instead of update to ensure it works for follow-up messages
    update_thinking_indicator(chat, "Thinking...")

    # Processing steps with progress updates
    begin
      # Step 1: Preparing request
      update_thinking_indicator(chat, "Preparing request...")
      sleep(0.5) # Small delay to show the progress

      # Step 2: Analyzing query
      update_thinking_indicator(chat, "Analyzing your question...")
      sleep(0.5) # Small delay to show the progress

      # Step 3: Generating response
      update_thinking_indicator(chat, "Generating response...")

      # Generate the actual response
      response_content = generate_response(chat, user_message.content)

      # Step 4: Finalizing
      update_thinking_indicator(chat, "Finalizing response...")
      sleep(0.5) # Small delay to show the progress

      # Create AI response
      ai_response = chat.messages.create!(
        role: "assistant",
        content: response_content
      )

      # Broadcast the response to the chat channel
      Turbo::StreamsChannel.broadcast_append_to(
        chat,
        target: "messages",
        partial: "messages/message",
        locals: { message: ai_response }
      )
    rescue => e
      Rails.logger.error("Error in ProcessAiResponseJob: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))

      # Create an error message if something went wrong
      error_message = chat.messages.create!(
        role: "assistant",
        content: "I'm sorry, I encountered an error while processing your request. Please try again later."
      )

      # Broadcast the error message
      Turbo::StreamsChannel.broadcast_append_to(
        chat,
        target: "messages",
        partial: "messages/message",
        locals: { message: error_message }
      )
    ensure
      # Hide the thinking indicator - use replace instead of update
      Turbo::StreamsChannel.broadcast_replace_to(
        chat,
        target: "thinking",
        html: '<div id="thinking" class="hidden"></div>'
      )

      # Reset the form
      Turbo::StreamsChannel.broadcast_replace_to(
        chat,
        target: "message_form",
        partial: "messages/form",
        locals: { chat: chat, message: Message.new, scroll_behavior: true }
      )
    end

    # Debug mode: Log completion
    Ai::DebugMode.log_to_chat(chat, "🐞 DEBUG: Processing completed")
  end

  private
    # Helper method to update the thinking indicator with progress
    def update_thinking_indicator(chat, message)
      Turbo::StreamsChannel.broadcast_replace_to(
        chat,
        target: "thinking",
        html: <<~HTML
          <div id="thinking" class="flex items-start gap-3">
            #{ApplicationController.render(partial: "chats/ai_avatar")}
            <div class="bg-gray-100 rounded-lg p-4 max-w-[85%] flex items-center">
              <div class="flex gap-1">
                <div class="w-2 h-2 bg-gray-400 rounded-full animate-bounce"></div>
                <div class="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style="animation-delay: 0.2s"></div>
                <div class="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style="animation-delay: 0.4s"></div>
              </div>
              <span class="ml-2 text-gray-600">#{message}</span>
            </div>
          </div>
        HTML
      )
    end

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

        # Process the query and get a response, passing the chat messages for context
        response = financial_assistant.query(user_message, chat.messages)

        response
      rescue => e
        error_message = "Error generating AI response: #{e.message}"
        Rails.logger.error(error_message)
        Rails.logger.error(e.backtrace.join("\n"))

        # Debug mode: Log error details
        # Limit the error message and backtrace to prevent payload size issues
        truncated_message = e.message.to_s[0...1000]
        truncated_backtrace = e.backtrace.first(5)

        Ai::DebugMode.log_to_chat(
          chat,
          "🐞 DEBUG: Error encountered",
          {
            error: truncated_message,
            backtrace: truncated_backtrace
          }
        )

        "I'm sorry, I encountered an error while processing your request. Please try again later."
      end
    end
end
