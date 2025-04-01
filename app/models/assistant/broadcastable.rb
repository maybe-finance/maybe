module Assistant::Broadcastable
  extend ActiveSupport::Concern

  private
    def update_thinking(thought)
      chat.broadcast_update target: "thinking-indicator", partial: "chats/thinking_indicator", locals: { chat: chat, message: thought }
    end

    def stop_thinking
      chat.broadcast_remove target: "thinking-indicator"
    end
end
