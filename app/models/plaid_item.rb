class PlaidItem < ApplicationRecord
  encrypts :item_access_token, deterministic: true
  validates :item_access_token, presence: true

  belongs_to :family
  has_one_attached :logo

  has_many :plaid_accounts, dependent: :destroy
  has_many :accounts, through: :plaid_accounts

  def has_issues?
    false
  end

  def syncing?
    false
  end
end
