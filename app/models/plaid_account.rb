class PlaidAccount < ApplicationRecord
  belongs_to :plaid_item

  has_one :account, dependent: :destroy
end
