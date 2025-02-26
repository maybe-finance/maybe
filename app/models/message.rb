class Message < ApplicationRecord
  belongs_to :chat
  belongs_to :user, optional: true

  enum :role, { user: "user", assistant: "assistant", system: "system" }

  validates :content, presence: true
  validates :role, presence: true

  after_create_commit -> { broadcast_append_to chat }

  # Check if the message is from a user
  def user?
    role == "user"
  end
end
