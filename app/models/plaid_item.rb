class PlaidItem < ApplicationRecord
  include Plaidable

  encrypts :access_token, deterministic: true
  validates :name, :access_token, presence: true

  before_destroy :remove_plaid_item

  belongs_to :family
  has_one_attached :logo

  has_many :plaid_accounts, dependent: :destroy
  has_many :accounts, through: :plaid_accounts

  class << self
    def create_from_public_token(token, item_name)
      response = plaid_provider.exchange_public_token(token)

      create!(
        name: item_name,
        access_token: response.access_token
      )
    end
  end

  def has_issues?
    false
  end

  def syncing?
    false
  end

  private
    def remove_plaid_item
      plaid_provider.remove_item(access_token)
    end
end
