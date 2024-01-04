class Message < ApplicationRecord
  belongs_to :conversation
  belongs_to :user, optional: true
  
  # Scope to only show messages that are not hidden
  scope :visible, -> { where(hidden: false) }
end
