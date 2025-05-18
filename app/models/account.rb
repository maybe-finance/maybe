class Account < ApplicationRecord
  include Syncable, Monetizable, Chartable, Linkable, Enrichable

  validates :name, :balance, :currency, presence: true

  belongs_to :family
  belongs_to :simple_fin_account, optional: true
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
  scope :manual, -> { where(plaid_account_id: nil, simple_fin_account_id: nil) }

  has_one_attached :logo

  delegated_type :accountable, types: Accountable::TYPES, dependent: :destroy

  accepts_nested_attributes_for :accountable, update_only: true

  before_destroy :destroy_associated_provider_accounts

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

  def syncing?
    self_syncing = syncs.visible.any?

    # Since Plaid Items sync as a "group", if the item is syncing, even if the account
    # sync hasn't yet started (i.e. we're still fetching the Plaid data), show it as syncing in UI.
    if linked?
      plaid_account&.plaid_item&.syncing? || simple_fin_account&.simple_fin_item&.syncing? || self_syncing
    else
      self_syncing
    end
  end

  def institution_domain
    url_string = if plaid_account.present?
      plaid_account.plaid_item&.institution_url
    elsif simple_fin_account.present?
      simple_fin_account.simple_fin_item&.institution_domain
    end

    return nil unless url_string.present?

    if simple_fin_account.present?
      # It's already the domain, so just return it.
      url_string
    else
      # It's a full URL (from Plaid), so parse it.
      begin
        URI.parse(url_string).host&.gsub(/^www\./, "")
      rescue URI::InvalidURIError
        Rails.logger.warn("Invalid institution URL encountered for Plaid account #{id}: #{url_string}")
        nil
      end
    end
  end

  def destroy_later
    update!(scheduled_for_deletion: true, is_active: false)
    DestroyJob.perform_later(self)
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

  def destroy_associated_provider_accounts
    simple_fin_account.destroy if simple_fin_account.present?
  end
end
