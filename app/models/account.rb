class Account < ApplicationRecord
  include Syncable, Monetizable, Issuable

  validates :name, :balance, :currency, presence: true

  belongs_to :family
  belongs_to :import, optional: true
  belongs_to :plaid_account, optional: true

  has_many :import_mappings, as: :mappable, dependent: :destroy, class_name: "Import::Mapping"
  has_many :entries, dependent: :destroy, class_name: "Account::Entry"
  has_many :transactions, through: :entries, source: :entryable, source_type: "Account::Transaction"
  has_many :valuations, through: :entries, source: :entryable, source_type: "Account::Valuation"
  has_many :trades, through: :entries, source: :entryable, source_type: "Account::Trade"
  has_many :holdings, dependent: :destroy, class_name: "Account::Holding"
  has_many :balances, dependent: :destroy
  has_many :issues, as: :issuable, dependent: :destroy

  monetize :balance, :cash_balance

  enum :classification, { asset: "asset", liability: "liability" }, validate: { allow_nil: true }

  scope :active, -> { where(is_active: true, scheduled_for_deletion: false) }
  scope :assets, -> { where(classification: "asset") }
  scope :liabilities, -> { where(classification: "liability") }
  scope :alphabetically, -> { order(:name) }
  scope :manual, -> { where(plaid_account_id: nil) }

  has_one_attached :logo

  delegated_type :accountable, types: Accountable::TYPES, dependent: :destroy

  accepts_nested_attributes_for :accountable, update_only: true

  def institution_domain
    return nil unless plaid_account&.plaid_item&.institution_url.present?
    URI.parse(plaid_account.plaid_item.institution_url).host.gsub(/^www\./, "")
  end

  class << self
    def by_group(period: Period.all, currency: Money.default_currency.iso_code)
      grouped_accounts = { assets: ValueGroup.new("Assets", currency), liabilities: ValueGroup.new("Liabilities", currency) }

      Accountable.by_classification.each do |classification, types|
        types.each do |type|
          accounts = self.where(accountable_type: type)
          if accounts.any?
            group = grouped_accounts[classification.to_sym].add_child_group(type, currency)
            accounts.each do |account|
              group.add_value_node(
                account,
                account.balance_money.exchange_to(currency, fallback_rate: 0),
                account.series(period: period, currency: currency)
              )
            end
          end
        end
      end

      grouped_accounts
    end

    def create_and_sync(attributes)
      attributes[:accountable_attributes] ||= {} # Ensure accountable is created, even if empty
      account = new(attributes.merge(cash_balance: attributes[:balance]))

      transaction do
        # Create 2 valuations for new accounts to establish a value history for users to see
        account.entries.build(
          name: "Current Balance",
          date: Date.current,
          amount: account.balance,
          currency: account.currency,
          entryable: Account::Valuation.new
        )
        account.entries.build(
          name: "Initial Balance",
          date: 1.day.ago.to_date,
          amount: 0,
          currency: account.currency,
          entryable: Account::Valuation.new
        )

        account.save!
      end

      account.sync_later
      account
    end
  end

  def destroy_later
    update!(scheduled_for_deletion: true)
    DestroyJob.perform_later(self)
  end

  def sync_data(start_date: nil)
    update!(last_synced_at: Time.current)

    Syncer.new(self, start_date: start_date).run
  end

  def post_sync
    broadcast_remove_to(family, target: "syncing-notice")
    resolve_stale_issues
    accountable.post_sync
  end

  def series(period: Period.last_30_days, currency: nil)
    balance_series = balances.in_period(period).where(currency: currency || self.currency)

    if balance_series.empty? && period.date_range.end == Date.current
      TimeSeries.new([ { date: Date.current, value: balance_money.exchange_to(currency || self.currency) } ])
    else
      TimeSeries.from_collection(balance_series, :balance_money, favorable_direction: asset? ? "up" : "down")
    end
  rescue Money::ConversionError
    TimeSeries.new([])
  end

  def original_balance
    balance_amount = balances.chronological.first&.balance || balance
    Money.new(balance_amount, currency)
  end

  def current_holdings
    holdings.where(currency: currency, date: holdings.maximum(:date)).order(amount: :desc)
  end

  def favorable_direction
    classification == "asset" ? "up" : "down"
  end

  def enrich_data
    DataEnricher.new(self).run
  end

  def update_with_sync!(attributes)
    should_update_balance = attributes[:balance] && attributes[:balance].to_d != balance

    transaction do
      update!(attributes)
      update_balance!(attributes[:balance]) if should_update_balance
    end

    sync_later
  end

  def update_balance!(balance)
    valuation = entries.account_valuations.find_by(date: Date.current)

    if valuation
      valuation.update! amount: balance
    else
      entries.create! \
        date: Date.current,
        name: "Balance update",
        amount: balance,
        currency: currency,
        entryable: Account::Valuation.new
    end
  end

  def transfer_match_candidates
    Account::Entry.select([
      "inflow_candidates.entryable_id as inflow_transaction_id",
      "outflow_candidates.entryable_id as outflow_transaction_id",
      "ABS(inflow_candidates.date - outflow_candidates.date) as date_diff"
    ]).from("account_entries inflow_candidates")
      .joins("
        JOIN account_entries outflow_candidates ON (
          inflow_candidates.amount < 0 AND
          outflow_candidates.amount > 0 AND
          inflow_candidates.amount = -outflow_candidates.amount AND
          inflow_candidates.currency = outflow_candidates.currency AND
          inflow_candidates.account_id <> outflow_candidates.account_id AND
          inflow_candidates.date BETWEEN outflow_candidates.date - 4 AND outflow_candidates.date + 4
        )
      ").joins("
        LEFT JOIN transfers existing_transfers ON (
          existing_transfers.inflow_transaction_id = inflow_candidates.entryable_id OR
          existing_transfers.outflow_transaction_id = outflow_candidates.entryable_id
        )
      ")
      .joins("LEFT JOIN rejected_transfers ON (
        rejected_transfers.inflow_transaction_id = inflow_candidates.entryable_id AND
        rejected_transfers.outflow_transaction_id = outflow_candidates.entryable_id
      )")
      .joins("JOIN accounts inflow_accounts ON inflow_accounts.id = inflow_candidates.account_id")
      .joins("JOIN accounts outflow_accounts ON outflow_accounts.id = outflow_candidates.account_id")
      .where("inflow_accounts.family_id = ? AND outflow_accounts.family_id = ?", self.family_id, self.family_id)
      .where("inflow_accounts.is_active = true AND inflow_accounts.scheduled_for_deletion = false")
      .where("outflow_accounts.is_active = true AND outflow_accounts.scheduled_for_deletion = false")
      .where("inflow_candidates.entryable_type = 'Account::Transaction' AND outflow_candidates.entryable_type = 'Account::Transaction'")
      .where(existing_transfers: { id: nil })
      .order("date_diff ASC") # Closest matches first
  end

  def auto_match_transfers!
    # Exclude already matched transfers
    candidates_scope = transfer_match_candidates.where(rejected_transfers: { id: nil })

    # Track which transactions we've already matched to avoid duplicates
    used_transaction_ids = Set.new

    candidates = []

    Transfer.transaction do
      candidates_scope.each do |match|
        next if used_transaction_ids.include?(match.inflow_transaction_id) ||
               used_transaction_ids.include?(match.outflow_transaction_id)

        Transfer.create!(
          inflow_transaction_id: match.inflow_transaction_id,
          outflow_transaction_id: match.outflow_transaction_id,
        )

        used_transaction_ids << match.inflow_transaction_id
        used_transaction_ids << match.outflow_transaction_id
      end
    end
  end
end
