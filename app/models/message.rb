class Message < ApplicationRecord
  belongs_to :chat
  belongs_to :user, optional: true
end
