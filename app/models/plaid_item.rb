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
    fetch_and_load_plaid_data(start_date: sync_record.start_date)

    accounts.each do |account|
      account.sync(start_date: sync_record.start_date, parent_sync: sync_record)
    end
  end

  private
    def fetch_and_load_plaid_data(start_date: nil)
      accounts_data = plaid_provider.get_item_accounts(self).accounts
      transactions_data = plaid_provider.get_item_transactions(self)

      transaction do
        accounts_data.each do |account_data|
          plaid_account = plaid_accounts.find_or_create_from_plaid_data!(account_data, family)
          plaid_account.sync_account_data!(account_data)
          plaid_account.sync_transactions!(transactions_data)
        end

        update!(prev_cursor: transactions_data.cursor)
      end
    end

    def remove_plaid_item
      plaid_provider.remove_item(access_token)
    end
end
