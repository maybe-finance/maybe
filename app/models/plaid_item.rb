class PlaidItem < ApplicationRecord
  include Plaidable, Syncable

  enum :plaid_region, { us: "us", eu: "eu" }

  if Rails.application.credentials.active_record_encryption.present?
    encrypts :access_token, deterministic: true
  end

  validates :name, :access_token, presence: true

  before_destroy :remove_plaid_item

  belongs_to :family
  has_one_attached :logo

  has_many :plaid_accounts, dependent: :destroy
  has_many :accounts, through: :plaid_accounts

  scope :active, -> { where(scheduled_for_deletion: false) }
  scope :ordered, -> { order(created_at: :desc) }

  class << self
    def create_from_public_token(token, item_name:, region:)
      response = plaid_provider_for_region(region).exchange_public_token(token)

      new_plaid_item = create!(
        name: item_name,
        plaid_id: response.item_id,
        access_token: response.access_token,
        plaid_region: region
      )

      new_plaid_item.sync_later
    end
  end

  def sync_data(start_date: nil)
    update!(last_synced_at: Time.current)

    plaid_data = fetch_and_load_plaid_data

    accounts.each do |account|
      account.sync_later(start_date: start_date)
    end

    plaid_data
  end

  def post_sync
    family.broadcast_refresh
  end

  def destroy_later
    update!(scheduled_for_deletion: true)
    DestroyJob.perform_later(self)
  end

  private
    def fetch_and_load_plaid_data
      data = {}
      item = plaid_provider.get_item(access_token).item
      update!(available_products: item.available_products, billed_products: item.billed_products)

      # Fetch and store institution details
      if item.institution_id.present?
        begin
          institution = plaid_provider.get_institution(item.institution_id)
          update!(
            institution_id: item.institution_id,
            institution_url: institution.institution.url,
            institution_color: institution.institution.primary_color
          )
        rescue Plaid::ApiError => e
          Rails.logger.warn("Error fetching institution details for item #{id}: #{e.message}")
        end
      end

      fetched_accounts = plaid_provider.get_item_accounts(self).accounts
      data[:accounts] = fetched_accounts || []

      internal_plaid_accounts = fetched_accounts.map do |account|
        internal_plaid_account = plaid_accounts.find_or_create_from_plaid_data!(account, family)
        internal_plaid_account.sync_account_data!(account)
        internal_plaid_account
      end

      fetched_transactions = safe_fetch_plaid_data(:get_item_transactions)
      data[:transactions] = fetched_transactions || []

      if fetched_transactions
        transaction do
          internal_plaid_accounts.each do |internal_plaid_account|
            added = fetched_transactions.added.select { |t| t.account_id == internal_plaid_account.plaid_id }
            modified = fetched_transactions.modified.select { |t| t.account_id == internal_plaid_account.plaid_id }
            removed = fetched_transactions.removed.select { |t| t.account_id == internal_plaid_account.plaid_id }

            internal_plaid_account.sync_transactions!(added:, modified:, removed:)
          end

          update!(next_cursor: fetched_transactions.cursor)
        end
      end

      fetched_investments = safe_fetch_plaid_data(:get_item_investments)
      data[:investments] = fetched_investments || []

      if fetched_investments
        transaction do
          internal_plaid_accounts.each do |internal_plaid_account|
            transactions = fetched_investments.transactions.select { |t| t.account_id == internal_plaid_account.plaid_id }
            holdings = fetched_investments.holdings.select { |h| h.account_id == internal_plaid_account.plaid_id }
            securities = fetched_investments.securities

            internal_plaid_account.sync_investments!(transactions:, holdings:, securities:)
          end
        end
      end

      fetched_liabilities = safe_fetch_plaid_data(:get_item_liabilities)
      data[:liabilities] = fetched_liabilities || []

      if fetched_liabilities
        transaction do
          internal_plaid_accounts.each do |internal_plaid_account|
            credit = fetched_liabilities.credit&.find { |l| l.account_id == internal_plaid_account.plaid_id }
            mortgage = fetched_liabilities.mortgage&.find { |l| l.account_id == internal_plaid_account.plaid_id }
            student = fetched_liabilities.student&.find { |l| l.account_id == internal_plaid_account.plaid_id }

            internal_plaid_account.sync_credit_data!(credit) if credit
            internal_plaid_account.sync_mortgage_data!(mortgage) if mortgage
            internal_plaid_account.sync_student_loan_data!(student) if student
          end
        end
      end

      data
    end

    def safe_fetch_plaid_data(method)
      begin
        plaid_provider.send(method, self)
      rescue Plaid::ApiError => e
        Rails.logger.warn("Error fetching #{method} for item #{id}: #{e.message}")
        nil
      end
    end

    def remove_plaid_item
      plaid_provider.remove_item(access_token)
    rescue StandardError => e
      Rails.logger.warn("Failed to remove Plaid item #{id}: #{e.message}")
    end
end
