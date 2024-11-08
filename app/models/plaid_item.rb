class PlaidItem < ApplicationRecord
  include Plaidable

  encrypts :access_token, deterministic: true
  validates :name, :access_token, presence: true

  before_destroy :remove_plaid_item

  belongs_to :family
  has_one_attached :logo

  has_many :syncs, class_name: "PlaidItemSync", dependent: :destroy
  has_many :plaid_accounts, dependent: :destroy
  has_many :accounts, through: :plaid_accounts

  class << self
    def create_from_public_token(token, item_name)
      response = plaid_provider.exchange_public_token(token)

      new_plaid_item = create!(
        name: item_name,
        plaid_id: response.item_id,
        access_token: response.access_token
      )

      new_plaid_item.sync_later
    end
  end

  def syncing?
    syncs.syncing.any?
  end

  def last_synced_at
    syncs.order(created_at: :desc).first&.last_ran_at
  end

  def sync_later
    PlaidItemSyncJob.perform_later(self)
  end

  def sync
    PlaidItemSync.create!(plaid_item: self).run
  end

  def fetch_accounts
    plaid_provider.get_item_accounts(self)
  end

  private
    def remove_plaid_item
      plaid_provider.remove_item(access_token)
    end
end
