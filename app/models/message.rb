class Message < ApplicationRecord
  include Promptable

  belongs_to :chat
  has_many :tool_calls, dependent: :destroy

  # Loosely follows the OpenAI model spec "roles" from "Chain of command"
  # https://model-spec.openai.com/2025-02-12.html#definitions
  enum :role, {
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
  validates :content, presence: true, allow_blank: true
  validate :kind_valid_for_role
  validate :status_valid_for_role

  after_create_commit :handle_create, if: :visible?
  after_update_commit -> { broadcast_update_to chat }, if: :visible?

  scope :ordered, -> { order(created_at: :asc) }
  scope :conversation, -> { where.not(kind: "debug") }
  scope :visible, -> { where(role: [ :user, :assistant ]) }

  def request_response_later
    chat.ask_assistant_later(self)
  end

  def request_response
    chat.ask_assistant(self)
  end

  private
    def visible?
      chat.debug_mode_enabled? || user? || assistant?
    end

    def handle_create
      broadcast_append_to chat

      request_response_later if user?
    end

    def status_valid_for_role
      if status == "pending" && role != "assistant"
        errors.add(:status, "All non-assistant messages must be complete on creation")
      end
    end

    def kind_valid_for_role
      if kind == "debug" && role != "developer"
        errors.add(:kind, "Debug messages must be developer")
      end

      if kind == "reasoning" && role != "assistant"
        errors.add(:kind, "Reasoning messages must be assistant")
      end
    end
end
