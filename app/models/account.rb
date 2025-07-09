class Account < ApplicationRecord
  InvalidBalanceError = Class.new(StandardError)

  include Syncable, Monetizable, Chartable, Linkable, Enrichable
  include AASM

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

  monetize :balance, :cash_balance, :non_cash_balance

  enum :classification, { asset: "asset", liability: "liability" }, validate: { allow_nil: true }

  scope :visible, -> { where(status: [ "draft", "active" ]) }
  scope :assets, -> { where(classification: "asset") }
  scope :liabilities, -> { where(classification: "liability") }
  scope :alphabetically, -> { order(:name) }
  scope :manual, -> { where(plaid_account_id: nil) }

  has_one_attached :logo

  delegated_type :accountable, types: Accountable::TYPES, dependent: :destroy

  accepts_nested_attributes_for :accountable, update_only: true

  # Account state machine
  aasm column: :status, timestamps: true do
    state :active, initial: true
    state :draft
    state :disabled
    state :pending_deletion

    event :activate do
      transitions from: [ :draft, :disabled ], to: :active
    end

    event :disable do
      transitions from: [ :draft, :active ], to: :disabled
    end

    event :enable do
      transitions from: :disabled, to: :active
    end

    event :mark_for_deletion do
      transitions from: [ :draft, :active, :disabled ], to: :pending_deletion
    end
  end

  class << self
    def create_and_sync(attributes)
      start_date = attributes.delete(:tracking_start_date) || 2.years.ago.to_date
      attributes[:accountable_attributes] ||= {} # Ensure accountable is created, even if empty
      account = new(attributes.merge(cash_balance: attributes[:balance]))
      initial_balance = attributes.dig(:accountable_attributes, :initial_balance)&.to_d || account.balance

      account.entries.build(
        name: Valuation::Name.new("opening_anchor", account.accountable_type).to_s,
        date: start_date,
        amount: initial_balance,
        currency: account.currency,
        entryable: Valuation.new(
          kind: "opening_anchor",
          balance: initial_balance,
          cash_balance: initial_balance
        )
      )

      account.save!
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
    mark_for_deletion!
    DestroyJob.perform_later(self)
  end

  # Override destroy to handle error recovery for accounts
  def destroy
    super
  rescue => e
    # If destruction fails, transition back to disabled state
    # This provides a cleaner recovery path than the generic scheduled_for_deletion flag
    disable! if may_disable?
    raise e
  end

  def current_holdings
    holdings.where(currency: currency)
            .where.not(qty: 0)
            .where(
              id: holdings.select("DISTINCT ON (security_id) id")
                          .where(currency: currency)
                          .order(:security_id, date: :desc)
            )
            .order(amount: :desc)
  end


  def update_balance(balance:, date: Date.current, currency: nil, notes: nil)
    Account::BalanceUpdater.new(self, balance:, currency:, date:, notes:).update
  end

  def update_current_balance(balance:, cash_balance:)
    raise InvalidBalanceError, "Cash balance cannot exceed balance" if cash_balance > balance

    if opening_anchor_valuation.present? && valuations.where(kind: "recon").empty?
      adjust_opening_balance_with_delta(balance:, cash_balance:)
    else
      reconcile_balance!(balance:, cash_balance:, date: Date.current)
    end
  end

  def reconcile_balance!(balance:, cash_balance:, date:)
    raise InvalidBalanceError, "Cash balance cannot exceed balance" if cash_balance > balance
    raise InvalidBalanceError, "Linked accounts cannot be reconciled" if linked?

    existing_valuation = valuations.joins(:entry).where(kind: "recon", entry: { date: Date.current }).first

    if existing_valuation.present?
      existing_valuation.update!(
        balance: balance,
        cash_balance: cash_balance
      )
    else
      entries.create!(
        date: date,
        name: Valuation::Name.new("recon", self.accountable_type),
        amount: balance,
        currency: self.currency,
        entryable: Valuation.new(
          kind: "recon",
          balance: balance,
          cash_balance: cash_balance
        )
      )
    end
  end

  def adjust_opening_balance_with_delta(balance:, cash_balance:)
    delta = self.balance - balance
    cash_delta = self.cash_balance - cash_balance

    set_or_update_opening_balance!(
      balance: balance - delta,
      cash_balance: cash_balance - cash_delta
    )
  end

  def set_or_update_opening_balance!(balance:, cash_balance:, date: nil)
    # A reasonable start date for most accounts to fill up adequate history for graphs
    fallback_opening_date = 2.years.ago.to_date

    raise InvalidBalanceError, "Cash balance cannot exceed balance" if cash_balance > balance

    transaction do
      if opening_anchor_valuation
        opening_anchor_valuation.update!(
          balance: balance,
          cash_balance: cash_balance
        )

        opening_anchor_valuation.entry.update!(amount: balance)
        opening_anchor_valuation.entry.update!(date: date) unless date.nil?

        opening_anchor_valuation
      else
        entry = entries.create!(
          date: date || fallback_opening_date,
          name: Valuation::Name.new("opening_anchor", self.accountable_type),
          amount: balance,
          currency: self.currency,
          entryable: Valuation.new(
            kind: "opening_anchor",
            balance: balance,
            cash_balance: cash_balance,
          )
        )

        entry.valuation
      end
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

  # For depository accounts, this is 0 (total balance is liquid cash)
  # For all other accounts, this represents "asset value" or "debt value"
  # (i.e. Investment accounts would refer to this as "holdings value")
  def non_cash_balance
    balance - cash_balance
  end

  private
    def opening_anchor_valuation
      valuations.opening_anchor.first
    end

    def current_anchor_valuation
      valuations.current_anchor.first
    end
end
