class Message < ApplicationRecord
  include Promptable

  belongs_to :chat
  has_many :tool_calls, dependent: :destroy

  # Loosely follows the OpenAI model spec "roles" from "Chain of command"
  # https://model-spec.openai.com/2025-02-12.html#definitions
  enum :role, {
    internal: "internal", # Internal use only
    developer: "developer", # Developer prompts
    user: "user", # User prompts
    assistant: "assistant" # Assistant responses
  }

  enum :kind, {
    text: "text",
    reasoning: "reasoning",
    debug: "debug"
  }

  enum :status, {
    pending: "pending",
    complete: "complete",
    failed: "failed"
  }

  validates :ai_model, presence: { if: -> { assistant? || user? } }
  validates :content, presence: true
  validate :kind_valid_for_role
  validate :status_valid_for_role

  after_create_commit :handle_create, if: :visible?
  after_update_commit -> { broadcast_update_to chat }, if: :visible?

  scope :ordered, -> { order(created_at: :asc) }
  scope :conversation, -> { Chat.debug_mode_enabled? ? ordered : ordered.where(role: [ :user, :assistant ], kind: [ "text", "reasoning" ]) }

  private
    def visible?
      chat.debug_mode_enabled? || user? || assistant?
    end

    def handle_create
      broadcast_append_to chat

      chat.assistant.respond_to_user if user?
    end

    def status_valid_for_role
      if status == "pending" && role != "assistant"
        errors.add(:status, "All non-assistant messages must be complete on creation")
      end
    end

    def kind_valid_for_role
      if kind == "debug" && role != "internal"
        errors.add(:kind, "Debug messages must be internal")
      end

      if kind == "reasoning" && role != "assistant"
        errors.add(:kind, "Reasoning messages must be assistant")
      end
    end
end
