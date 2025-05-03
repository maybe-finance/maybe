class Account < ApplicationRecord
  include Syncable, Monetizable, Chartable, Linkable, Convertible, Enrichable

  validates :name, :balance, :currency, presence: true

  belongs_to :family
  belongs_to :import, optional: true

  has_many :import_mappings, as: :mappable, dependent: :destroy, class_name: "Import::Mapping"
  has_many :entries, dependent: :destroy
  has_many :transactions, through: :entries, source: :entryable, source_type: "Transaction"
  has_many :valuations, through: :entries, source: :entryable, source_type: "Valuation"
  has_many :trades, through: :entries, source: :entryable, source_type: "Trade"
  has_many :holdings, dependent: :destroy
  has_many :balances, dependent: :destroy

  monetize :balance, :cash_balance

  enum :classification, { asset: "asset", liability: "liability" }, validate: { allow_nil: true }

  scope :active, -> { where(is_active: true) }
  scope :assets, -> { where(classification: "asset") }
  scope :liabilities, -> { where(classification: "liability") }
  scope :alphabetically, -> { order(:name) }
  scope :manual, -> { where(plaid_account_id: nil) }

  has_one_attached :logo

  delegated_type :accountable, types: Accountable::TYPES, dependent: :destroy

  accepts_nested_attributes_for :accountable, update_only: true

  class << self
    def create_and_sync(attributes)
      attributes[:accountable_attributes] ||= {} # Ensure accountable is created, even if empty
      account = new(attributes.merge(cash_balance: attributes[:balance]))
      initial_balance = attributes.dig(:accountable_attributes, :initial_balance)&.to_d || 0

      transaction do
        # Create 2 valuations for new accounts to establish a value history for users to see
        account.entries.build(
          name: "Current Balance",
          date: Date.current,
          amount: account.balance,
          currency: account.currency,
          entryable: Valuation.new
        )
        account.entries.build(
          name: "Initial Balance",
          date: 1.day.ago.to_date,
          amount: initial_balance,
          currency: account.currency,
          entryable: Valuation.new
        )

        account.save!
      end

      account.sync_later
      account
    end
  end

  def institution_domain
    url_string = plaid_account&.plaid_item&.institution_url
    return nil unless url_string.present?

    begin
      uri = URI.parse(url_string)
      # Use safe navigation on .host before calling gsub
      uri.host&.gsub(/^www\./, "")
    rescue URI::InvalidURIError
      # Log a warning if the URL is invalid and return nil
      Rails.logger.warn("Invalid institution URL encountered for account #{id}: #{url_string}")
      nil
    end
  end

  def destroy_later
    update!(scheduled_for_deletion: true, is_active: false)
    DestroyJob.perform_later(self)
  end

  def sync_data(sync, start_date: nil)
    update!(last_synced_at: Time.current)

    Rails.logger.info("Processing balances (#{linked? ? 'reverse' : 'forward'})")
    sync_balances
  end

  def post_sync(sync)
    family.remove_syncing_notice!

    accountable.post_sync(sync)

    unless sync.child?
      family.auto_match_transfers!
    end
  end

  def current_holdings
    holdings.where(currency: currency, date: holdings.maximum(:date)).order(amount: :desc)
  end

  def update_with_sync!(attributes)
    should_update_balance = attributes[:balance] && attributes[:balance].to_d != balance

    initial_balance = attributes.dig(:accountable_attributes, :initial_balance)
    should_update_initial_balance = initial_balance && initial_balance.to_d != accountable.initial_balance

    transaction do
      update!(attributes)
      update_balance!(attributes[:balance]) if should_update_balance
      update_inital_balance!(attributes[:accountable_attributes][:initial_balance]) if should_update_initial_balance
    end

    sync_later
  end

  def update_balance!(balance)
    valuation = entries.valuations.find_by(date: Date.current)

    if valuation
      valuation.update! amount: balance
    else
      entries.create! \
        date: Date.current,
        name: "Balance update",
        amount: balance,
        currency: currency,
        entryable: Valuation.new
    end
  end

  def update_inital_balance!(initial_balance)
    valuation = first_valuation

    if valuation
      valuation.update! amount: initial_balance
    else
      entries.create! \
        date: Date.current,
        name: "Initial Balance",
        amount: initial_balance,
        currency: currency,
        entryable: Valuation.new
    end
  end

  def start_date
    first_entry_date = entries.minimum(:date) || Date.current
    first_entry_date - 1.day
  end

  def lock_saved_attributes!
    super
    accountable.lock_saved_attributes!
  end

  def first_valuation
    entries.valuations.order(:date).first
  end

  def first_valuation_amount
    first_valuation&.amount_money || balance_money
  end

  # Get short version of the subtype label
  def short_subtype_label
    accountable_class.short_subtype_label_for(subtype) || accountable_class.display_name
  end

  # Get long version of the subtype label
  def long_subtype_label
    accountable_class.long_subtype_label_for(subtype) || accountable_class.display_name
  end

  private
    def sync_balances
      strategy = linked? ? :reverse : :forward
      Balance::Syncer.new(self, strategy: strategy).sync_balances
    end
end
