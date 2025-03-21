class Chat < ApplicationRecord
  include Debuggable

  belongs_to :user

  has_one :viewer, class_name: "User", foreign_key: :last_viewed_chat_id, dependent: :nullify # "Last chat user has viewed"
  has_many :messages, dependent: :destroy

  validates :title, presence: true

  scope :ordered, -> { order(created_at: :desc) }

  class << self
    def create_from_prompt!(prompt, developer_prompt: nil)
      create!(
        title: prompt.first(20),
        messages: [ Message.new(kind: "text", role: "user", content: prompt) ]
      )
    end
  end

  def assistant
    @assistant ||= Assistant.for_chat(self)
  end
end
