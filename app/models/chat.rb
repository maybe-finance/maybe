class Chat < ApplicationRecord
  include Debuggable

  belongs_to :user

  has_one :viewer, class_name: "User", foreign_key: :last_viewed_chat_id, dependent: :nullify # "Last chat user has viewed"
  has_many :messages, dependent: :destroy

  validates :title, presence: true

  scope :ordered, -> { order(created_at: :desc) }

  class << self
    def start!(prompt, model:)
      create!(
        title: generate_title(prompt),
        messages: [ UserMessage.new(content: prompt, ai_model: model) ]
      )
    end

    def generate_title(prompt)
      prompt.first(20)
    end
  end

  def assistant
    @assistant ||= Assistant.for_chat(self)
  end

  def ask_assistant_later(message)
    AssistantResponseJob.perform_later(message)
  end

  def ask_assistant(message)
    assistant.respond_to(message)
  end

  def conversation_messages
    if debug_mode?
      messages
    else
      messages.where(type: ["UserMessage", "AssistantMessage"])
    end
  end
end
