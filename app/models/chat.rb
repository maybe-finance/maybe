class Chat < ApplicationRecord
  belongs_to :user

  has_one :viewer, class_name: "User", foreign_key: :current_chat_id, dependent: :nullify # "Last chat user has viewed"
  has_many :messages, dependent: :destroy

  validates :title, presence: true

  scope :ordered, -> { order(created_at: :desc) }
end
