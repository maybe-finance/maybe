class Family < ApplicationRecord
  include PlaidConnectable, SimpleFinConnectable, Syncable, AutoTransferMatchable, Subscribeable

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

  # If any accounts or plaid items are syncing, the family is also syncing, even if a formal "Family Sync" is not running.
  def syncing?
    Sync.joins("LEFT JOIN plaid_items ON plaid_items.id = syncs.syncable_id AND syncs.syncable_type = 'PlaidItem'")
        .joins("LEFT JOIN simple_fin_items ON simple_fin_items.id = syncs.syncable_id AND syncs.syncable_type = 'SimpleFinItem'")
        .joins("LEFT JOIN accounts ON accounts.id = syncs.syncable_id AND syncs.syncable_type = 'Account'")
        .where("syncs.syncable_id = ? OR accounts.family_id = ? OR plaid_items.family_id = ?", id, id, id)
        .visible
        .exists?
  end

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

  def eu?
    country != "US" && country != "CA"
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

  def oldest_entry_date
    entries.order(:date).first&.date || Date.current
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
