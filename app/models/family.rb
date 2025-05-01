class Family < ApplicationRecord
  include Syncable, AutoTransferMatchable

  DATE_FORMATS = [
    [ "MM-DD-YYYY", "%m-%d-%Y" ],
    [ "DD.MM.YYYY", "%d.%m.%Y" ],
    [ "DD-MM-YYYY", "%d-%m-%Y" ],
    [ "YYYY-MM-DD", "%Y-%m-%d" ],
    [ "DD/MM/YYYY", "%d/%m/%Y" ],
    [ "YYYY/MM/DD", "%Y/%m/%d" ],
    [ "MM/DD/YYYY", "%m/%d/%Y" ],
    [ "D/MM/YYYY", "%e/%m/%Y" ],
    [ "YYYY.MM.DD", "%Y.%m.%d" ]
  ].freeze

  has_many :users, dependent: :destroy
  has_many :accounts, dependent: :destroy
  has_many :plaid_items, dependent: :destroy
  has_many :invitations, dependent: :destroy

  has_many :imports, dependent: :destroy

  has_many :entries, through: :accounts
  has_many :transactions, through: :accounts
  has_many :rules, dependent: :destroy
  has_many :trades, through: :accounts
  has_many :holdings, through: :accounts

  has_many :tags, dependent: :destroy
  has_many :categories, dependent: :destroy
  has_many :merchants, dependent: :destroy, class_name: "FamilyMerchant"

  has_many :budgets, dependent: :destroy
  has_many :budget_categories, through: :budgets

  validates :locale, inclusion: { in: I18n.available_locales.map(&:to_s) }
  validates :date_format, inclusion: { in: DATE_FORMATS.map(&:last) }

  def assigned_merchants
    merchant_ids = transactions.where.not(merchant_id: nil).pluck(:merchant_id).uniq
    Merchant.where(id: merchant_ids)
  end

  def auto_categorize_transactions_later(transactions)
    AutoCategorizeJob.perform_later(self, transaction_ids: transactions.pluck(:id))
  end

  def auto_categorize_transactions(transaction_ids)
    AutoCategorizer.new(self, transaction_ids: transaction_ids).auto_categorize
  end

  def auto_detect_transaction_merchants_later(transactions)
    AutoDetectMerchantsJob.perform_later(self, transaction_ids: transactions.pluck(:id))
  end

  def auto_detect_transaction_merchants(transaction_ids)
    AutoMerchantDetector.new(self, transaction_ids: transaction_ids).auto_detect
  end

  def balance_sheet
    @balance_sheet ||= BalanceSheet.new(self)
  end

  def income_statement
    @income_statement ||= IncomeStatement.new(self)
  end

  def sync_data(sync, start_date: nil)
    update!(last_synced_at: Time.current)

    Rails.logger.info("Syncing accounts for family #{id}")
    accounts.manual.each do |account|
      account.sync_later(start_date: start_date, parent_sync: sync)
    end

    Rails.logger.info("Syncing plaid items for family #{id}")
    plaid_items.each do |plaid_item|
      plaid_item.sync_later(start_date: start_date, parent_sync: sync)
    end

    Rails.logger.info("Applying rules for family #{id}")
    rules.each do |rule|
      rule.apply_later
    end
  end

  def remove_syncing_notice!
    broadcast_remove target: "syncing-notice"
  end

  def post_sync(sync)
    auto_match_transfers!
    broadcast_refresh
  end

  # If family has any syncs pending/syncing within the last hour, we show a persistent "syncing" notice.
  # Ignore syncs older than 1 hour as they are considered "stale"
  def syncing?
    Sync.where(
      "(syncable_type = 'Family' AND syncable_id = ?) OR
       (syncable_type = 'Account' AND syncable_id IN (SELECT id FROM accounts WHERE family_id = ? AND plaid_account_id IS NULL)) OR
       (syncable_type = 'PlaidItem' AND syncable_id IN (SELECT id FROM plaid_items WHERE family_id = ?))",
      id, id, id
    ).where(status: [ "pending", "syncing" ], created_at: 1.hour.ago..).exists?
  end

  def eu?
    country != "US" && country != "CA"
  end

  def get_link_token(webhooks_url:, redirect_url:, accountable_type: nil, region: :us, access_token: nil)
    provider = if region.to_sym == :eu
      Provider::Registry.get_provider(:plaid_eu)
    else
      Provider::Registry.get_provider(:plaid_us)
    end

    # early return when no provider
    return nil unless provider

    provider.get_link_token(
      user_id: id,
      webhooks_url: webhooks_url,
      redirect_url: redirect_url,
      accountable_type: accountable_type,
      access_token: access_token
    ).link_token
  end

  def subscribed?
    stripe_subscription_status == "active"
  end

  def trialing?
    !subscribed? && trial_started_at.present? && trial_started_at <= 14.days.from_now
  end

  def trial_remaining_days
    (14 - (Time.current - trial_started_at).to_i / 86400).to_i
  end

  def existing_customer?
    stripe_customer_id.present?
  end

  def requires_data_provider?
    # If family has any trades, they need a provider for historical prices
    return true if trades.any?

    # If family has any accounts not denominated in the family's currency, they need a provider for historical exchange rates
    return true if accounts.where.not(currency: self.currency).any?

    # If family has any entries in different currencies, they need a provider for historical exchange rates
    uniq_currencies = entries.pluck(:currency).uniq
    return true if uniq_currencies.count > 1
    return true if uniq_currencies.count > 0 && uniq_currencies.first != self.currency

    false
  end

  def missing_data_provider?
    requires_data_provider? && Provider::Registry.get_provider(:synth).nil?
  end

  def primary_user
    users.order(:created_at).first
  end

  def oldest_entry_date
    entries.order(:date).first&.date || Date.current
  end

  def active_accounts_count
    accounts.active.count
  end

  # Cache key that is invalidated when any of the family's entries are updated (which affect rollups and other calculations)
  def build_cache_key(key)
    [
      "family",
      id,
      key,
      entries.maximum(:updated_at)
    ].compact.join("_")
  end

  def self_hoster?
    Rails.application.config.app_mode.self_hosted?
  end
end
