class PlaidItem < ApplicationRecord
  include Plaidable, Syncable

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

      new_plaid_item = create!(
        name: item_name,
        plaid_id: response.item_id,
        access_token: response.access_token
      )

      new_plaid_item.sync_later
    end
  end

  def sync_data(sync_record)
    fetch_and_load_plaid_data

    accounts.each do |account|
      account.sync(start_date: sync_record.start_date, parent_sync: sync_record)
    end
  end

  def fetch_accounts
    plaid_provider.get_item_accounts(self)
  end

  private
    def fetch_and_load_plaid_data
      # TODO
      puts "fetching and loading plaid data"
    end

    def remove_plaid_item
      plaid_provider.remove_item(access_token)
    end
end
