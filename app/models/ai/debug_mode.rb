module Ai
  module DebugMode
    # Check if debug mode is enabled
    def self.enabled?
      ENV["AI_DEBUG_MODE"] == "true"
    end

    # Log debug information to a chat
    def self.log_to_chat(chat, message, data = nil)
      return unless enabled?

      content = message
      if data.present?
        content += "\n\n```json\n#{JSON.pretty_generate(data)}\n```"
      end

      chat.messages.create!(
        role: "system",
        content: content
      )
    end
  end
end
