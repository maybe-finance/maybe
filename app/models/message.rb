class Message < ApplicationRecord
  belongs_to :chat
  belongs_to :user, optional: true

  enum :role, { user: "user", assistant: "assistant", system: "system" }

  validates :content, presence: true
  validates :role, presence: true
end
