class PlaidItem < ApplicationRecord
  include Provided, Syncable

  enum :plaid_region, { us: "us", eu: "eu" }
  enum :status, { good: "good", requires_update: "requires_update" }, default: :good

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
  scope :needs_update, -> { where(status: :requires_update) }

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

  def sync_data(sync, start_date: nil)
    update!(last_synced_at: Time.current)

    begin
      Rails.logger.info("Fetching and loading Plaid data")
      plaid_data = fetch_and_load_plaid_data
      update!(status: :good) if requires_update?

      # Schedule account syncs
      accounts.each do |account|
        account.sync_later(start_date: start_date)
      end

      Rails.logger.info("Plaid data fetched and loaded")
      plaid_data
    rescue Plaid::ApiError => e
      handle_plaid_error(e)
      raise e
    end
  end

  def get_update_link_token(webhooks_url:, redirect_url:)
    begin
      family.get_link_token(
        webhooks_url: webhooks_url,
        redirect_url: redirect_url,
        region: plaid_region,
        access_token: access_token
      )
    rescue Plaid::ApiError => e
      error_body = JSON.parse(e.response_body)

      if error_body["error_code"] == "ITEM_NOT_FOUND"
        # Mark the connection as invalid but don't auto-delete
        update!(status: :requires_update)
        raise PlaidConnectionLostError
      else
        raise e
      end
    end
  end

  def post_sync(sync)
    auto_match_categories!
    family.broadcast_refresh
  end

  def destroy_later
    update!(scheduled_for_deletion: true)
    DestroyJob.perform_later(self)
  end

  def auto_match_categories!
    if family.categories.none?
      family.categories.bootstrap!
    end

    alias_matcher = build_category_alias_matcher(family.categories)

    accounts.each do |account|
      matchable_transactions = account.transactions
                                      .where(category_id: nil)
                                      .where.not(plaid_category: nil)
                                      .enrichable(:category_id)

      matchable_transactions.each do |transaction|
        category = alias_matcher.match(transaction.plaid_category_detailed)

        if category.present?
          PlaidItem.transaction do
            transaction.log_enrichment!(
              attribute_name: "category_id",
              attribute_value: category.id,
              source: "plaid"
            )
            transaction.set_category!(category)
          end
        end
      end
    end
  end

  private
    def fetch_and_load_plaid_data
      data = {}

      # Log what we're about to fetch
      Rails.logger.info "Starting Plaid data fetch (accounts, transactions, investments, liabilities)"

      item = plaid_provider.get_item(access_token).item
      update!(available_products: item.available_products, billed_products: item.billed_products)

      # Institution details
      if item.institution_id.present?
        begin
          Rails.logger.info "Fetching Plaid institution details for #{item.institution_id}"
          institution = plaid_provider.get_institution(item.institution_id)
          update!(
            institution_id: item.institution_id,
            institution_url: institution.institution.url,
            institution_color: institution.institution.primary_color
          )
        rescue Plaid::ApiError => e
          Rails.logger.warn "Failed to fetch Plaid institution details: #{e.message}"
        end
      end

      # Accounts
      fetched_accounts = plaid_provider.get_item_accounts(self).accounts
      data[:accounts] = fetched_accounts || []
      Rails.logger.info "Processing Plaid accounts (count: #{fetched_accounts.size})"

      internal_plaid_accounts = fetched_accounts.map do |account|
        internal_plaid_account = plaid_accounts.find_or_create_from_plaid_data!(account, family)
        internal_plaid_account.sync_account_data!(account)
        internal_plaid_account
      end

      # Transactions
      fetched_transactions = safe_fetch_plaid_data(:get_item_transactions)
      data[:transactions] = fetched_transactions || []

      if fetched_transactions
        Rails.logger.info "Processing Plaid transactions (added: #{fetched_transactions.added.size}, modified: #{fetched_transactions.modified.size}, removed: #{fetched_transactions.removed.size})"
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

      # Investments
      fetched_investments = safe_fetch_plaid_data(:get_item_investments)
      data[:investments] = fetched_investments || []

      if fetched_investments
        Rails.logger.info "Processing Plaid investments (transactions: #{fetched_investments.transactions.size}, holdings: #{fetched_investments.holdings.size}, securities: #{fetched_investments.securities.size})"
        transaction do
          internal_plaid_accounts.each do |internal_plaid_account|
            transactions = fetched_investments.transactions.select { |t| t.account_id == internal_plaid_account.plaid_id }
            holdings = fetched_investments.holdings.select { |h| h.account_id == internal_plaid_account.plaid_id }
            securities = fetched_investments.securities

            internal_plaid_account.sync_investments!(transactions:, holdings:, securities:)
          end
        end
      end

      # Liabilities
      fetched_liabilities = safe_fetch_plaid_data(:get_item_liabilities)
      data[:liabilities] = fetched_liabilities || []

      if fetched_liabilities
        Rails.logger.info "Processing Plaid liabilities (credit: #{fetched_liabilities.credit&.size || 0}, mortgage: #{fetched_liabilities.mortgage&.size || 0}, student: #{fetched_liabilities.student&.size || 0})"
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

    def handle_plaid_error(error)
      error_body = JSON.parse(error.response_body)

      if error_body["error_code"] == "ITEM_LOGIN_REQUIRED"
        update!(status: :requires_update)
      end
    end

    class PlaidConnectionLostError < StandardError; end
end
