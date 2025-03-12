class Chat < ApplicationRecord
  belongs_to :user
  has_many :messages, dependent: :destroy
  has_one :user_current_chat, class_name: "User", foreign_key: :current_chat_id, dependent: :nullify

  validates :title, presence: true

  scope :ordered, -> { order(created_at: :desc) }

  class << self
    def create_with_defaults!
      create!(
        title: "New chat #{Time.current.strftime("%Y-%m-%d %H:%M:%S")}",
        messages: [
          Message.new(
            role: "system",
            content: "You are a helpful personal finance assistant.",
          )
        ]
      )
    end
  end

  def generate_next_ai_response
    if messages.conversation.ordered.last&.role == "assistant"
      Rails.logger.info("Skipping response because last message was an assistant message")
      return
    end

    openai.chat(
      parameters: {
        model: "gpt-4o-mini",
        stream: streamer,
        n: 1,
        messages: messages.conversation.order(:created_at).map do |message|
          {
            role: message.role,
            content: message.content
          }
        end
      }
    )
  end

  private
    def openai
      OpenAI::Client.new(access_token: ENV["OPENAI_ACCESS_TOKEN"])
    end

    def streamer
      message = messages.create!(
        role: "assistant",
        content: ""
      )

      proc do |chunk, _bytesize|
        new_content = chunk.dig("choices", 0, "delta", "content")
        message.update(content: message.content + new_content) if new_content
      end
    end
end
