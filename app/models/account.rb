class Account < ApplicationRecord
  include Syncable
  include Monetizable

  broadcasts_refreshes

  validates :family, presence: true

  belongs_to :family
  belongs_to :institution, optional: true

  has_many :entries, dependent: :destroy, class_name: "Account::Entry"
  has_many :transactions, through: :entries, source: :entryable, source_type: "Account::Transaction"
  has_many :valuations, through: :entries, source: :entryable, source_type: "Account::Valuation"
  has_many :trades, through: :entries, source: :entryable, source_type: "Account::Trade"
  has_many :balances, dependent: :destroy
  has_many :imports, dependent: :destroy
  has_many :syncs, dependent: :destroy

  monetize :balance

  enum :classification, { asset: "asset", liability: "liability" }, validate: { allow_nil: true }

  scope :active, -> { where(is_active: true) }
  scope :assets, -> { where(classification: "asset") }
  scope :liabilities, -> { where(classification: "liability") }
  scope :alphabetically, -> { order(:name) }
  scope :ungrouped, -> { where(institution_id: nil) }

  delegated_type :accountable, types: Accountable::TYPES, dependent: :destroy

  class << self
    def by_group(period: Period.all, currency: Money.default_currency)
      grouped_accounts = { assets: ValueGroup.new("Assets", currency), liabilities: ValueGroup.new("Liabilities", currency) }

      Accountable.by_classification.each do |classification, types|
        types.each do |type|
          group = grouped_accounts[classification.to_sym].add_child_group(type, currency)
          self.where(accountable_type: type).each do |account|
            group.add_value_node(
              account,
              account.balance_money.exchange_to(currency) || Money.new(0, currency),
              account.series(period: period, currency: currency)
            )
          end
        end
      end

      grouped_accounts
    end

    def create_with_optional_start_balance!(attributes:, start_date: nil, start_balance: nil)
      account = self.new(attributes.except(:accountable_type))
      account.accountable = Accountable.from_type(attributes[:accountable_type])&.new

      # Always build the initial valuation
      account.entries.build \
        date: Date.current,
        amount: attributes[:balance],
        currency: account.currency,
        entryable: Account::Valuation.new

      # Conditionally build the optional start valuation
      if start_date.present? && start_balance.present?
        account.entries.build \
          date: start_date,
          amount: start_balance,
          currency: account.currency,
          entryable: Account::Valuation.new
      end

      account.save!
      account
    end
  end

  # e.g. Wise, Revolut accounts that have transactions in multiple currencies
  def multi_currency?
    entries.select(:currency).distinct.count > 1
  end

  # e.g. Accounts denominated in currency other than family currency
  def foreign_currency?
    currency != family.currency
  end

  def alert
    latest_sync = syncs.latest
    [ latest_sync&.error, *latest_sync&.warnings ].compact.first
  end

  def syncing?
    syncs.syncing.any?
  end

  def sync_later(start_date = nil)
    AccountSyncJob.perform_later(self, start_date)
  end

  def sync(start_date = nil)
    ordered_syncables = [ ExchangeRate, Security::Price, Account::Holding, Account::Balance ]

    Account::Sync.for(self, start_date)
                 .start(ordered_syncables)
  end

  # The earliest date we can calculate a balance for
  def effective_start_date
    @effective_start_date ||= entries.order(:date).first.try(:date) || Date.current
  end

  def favorable_direction
    classification == "asset" ? "up" : "down"
  end

  def required_exchange_rates(start_date = nil)
    calculation_start_date = [ start_date, effective_start_date ].compact.max
    required_rates = []

    if foreign_currency?
      required_rates += (calculation_start_date..Date.current).map do |date|
        { date: date, from: self.currency, to: family.currency }
      end
    end

    foreign_entries = self.entries
                          .where("date >= ?", calculation_start_date)
                          .where.not(currency: family.currency)
                          .pluck(:currency, :date)

    required_rates += foreign_entries.map do |currency, date|
      { date: date, from: currency, to: family.currency }
    end

    required_rates.compact.uniq
  end

  def required_securities_prices
    {
      isin_codes: self.trades.includes(:security).map { |trade| trade.security.isin }.uniq,
      start_date: effective_start_date
    }
  end

  def series(period: Period.all, currency: self.currency)
    balance_series = balances.in_period(period).where(currency: Money::Currency.new(currency).iso_code)

    if balance_series.empty? && period.date_range.end == Date.current
      converted_balance = balance_money.exchange_to(currency)
      if converted_balance
        TimeSeries.new([ { date: Date.current, value: converted_balance } ])
      else
        TimeSeries.new([])
      end
    else
      TimeSeries.from_collection(balance_series, :balance_money)
    end
  end
end
