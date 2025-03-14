class Message < ApplicationRecord
  include Promptable

  belongs_to :chat

  # Matches OpenAI model spec "roles" from "Chain of command"
  # https://model-spec.openai.com/2025-02-12.html#definitions
  enum :role, {
    developer: "developer",
    user: "user",
    assistant: "assistant"
  }

  enum :message_type, {
    text: "text",
    function: "function_call",
    debug: "debug" # internal only, never sent to OpenAI
  }

  validates :content, presence: true

  after_create_commit :broadcast_and_fetch
  after_update_commit -> { broadcast_update_to chat }

  scope :conversation, -> { where(message_type: [ :text ], role: [ :user, :assistant ]) }
  scope :ordered, -> { order(created_at: :asc) }

  private
    def broadcast_and_fetch
      broadcast_append_to chat

      if user?
        stream_openai_response
      end
    end

    def stream_openai_response
      # TODO
      Rails.logger.info "Streaming OpenAI response"
    end

    def streamer
      # TODO

      proc do |chunk, _bytesize|
        Rails.logger.info "OpenAI response chunk: #{chunk}"
      end
    end
end
