module Ai
  module DebugMode
    # Check if debug mode is enabled
    def self.enabled?
      ENV["AI_DEBUG_MODE"] == "true"
    end

    # Log debug information to a chat
    def self.log_to_chat(chat, message, data = nil)
      return unless enabled?

      # Store debug messages in the database but don't output to chat
      content = message
      if data.present?
        # Limit the size of the JSON data to prevent PostgreSQL NOTIFY payload size limit errors
        if data.is_a?(Hash) && data[:backtrace].is_a?(Array)
          # Limit backtrace to first 3 entries to reduce payload size
          data[:backtrace] = data[:backtrace].first(3)
        end

        # Convert to JSON and check size
        json_data = JSON.pretty_generate(data)

        # If still too large, truncate it (PostgreSQL NOTIFY has ~8000 byte limit)
        if json_data.bytesize > 7000
          json_data = json_data[0...7000] + "\n... (truncated due to size limits)"
        end

        content += "\n\n```json\n#{json_data}\n```"
      end

      # Create the message with internal flag set to true so it's not displayed in the chat UI
      chat.messages.create!(
        role: "system",
        content: content,
        internal: true
      )
    end
  end
end
