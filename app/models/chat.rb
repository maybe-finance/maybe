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
end
