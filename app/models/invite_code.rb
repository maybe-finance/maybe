class InviteCode < ApplicationRecord
  belongs_to :user, optional: true
end
