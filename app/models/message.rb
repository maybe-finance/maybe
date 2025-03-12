class Message < ApplicationRecord
  belongs_to :chat

  enum :role, { user: "user", assistant: "assistant", system: "system" }

  validates :content, presence: true, allow_blank: true
  validates :role, presence: true

  scope :conversation, -> { where(debug_mode: false, role: [ :user, :assistant ]) }
  scope :ordered, -> { order(created_at: :asc) }

  after_create_commit :broadcast_to_chat
  after_update_commit :broadcast_update_to_chat

  private
    def broadcast_to_chat
      broadcast_append_to(
        chat,
        partial: "messages/message",
        locals: { message: self },
        target: "chat_#{chat.id}_messages"
      )
    end

    def broadcast_update_to_chat
      broadcast_update_to(
        chat,
        partial: "messages/message",
        locals: { message: self },
        target: "message_#{self.id}"
      )
    end
end
