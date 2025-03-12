class Message < ApplicationRecord
  belongs_to :chat

  enum :role, { user: "user", assistant: "assistant", system: "system" }

  validates :content, presence: true
  validates :role, presence: true

  scope :conversation, -> { where(debug_mode: false, role: [ :user, :assistant ]) }
end
