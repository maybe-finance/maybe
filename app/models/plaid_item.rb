class PlaidItem < ApplicationRecord
  encrypts :item_access_token, deterministic: true
  validates :item_access_token, presence: true

  belongs_to :family
end
