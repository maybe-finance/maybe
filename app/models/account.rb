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
              account.balance_money.exchange_to(currency, fallback_rate: 0),
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

  def favorable_direction
    classification == "asset" ? "up" : "down"
  end

  def series(period: Period.all, currency: self.currency)
    balance_series = balances.in_period(period).where(currency: Money::Currency.new(currency).iso_code)

    if balance_series.empty? && period.date_range.end == Date.current
      TimeSeries.new([ { date: Date.current, value: balance_money.exchange_to(currency) } ])
    else
      TimeSeries.from_collection(balance_series, :balance_money)
    end
  rescue Money::ConversionError
    TimeSeries.new([])
  end
end
