class InviteCode < ApplicationRecord
  has_secure_token :code
end
