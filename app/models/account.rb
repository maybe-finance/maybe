class Account < ApplicationRecord
  include Syncable, Monetizable, Issuable

  validates :name, :balance, :currency, presence: true

  belongs_to :family
  belongs_to :institution, optional: true
  belongs_to :import, optional: true

  has_many :import_mappings, as: :mappable, dependent: :destroy, class_name: "Import::Mapping"
  has_many :entries, dependent: :destroy, class_name: "Account::Entry"
  has_many :transactions, through: :entries, source: :entryable, source_type: "Account::Transaction"
  has_many :valuations, through: :entries, source: :entryable, source_type: "Account::Valuation"
  has_many :trades, through: :entries, source: :entryable, source_type: "Account::Trade"
  has_many :holdings, dependent: :destroy
  has_many :balances, dependent: :destroy
  has_many :syncs, dependent: :destroy
  has_many :issues, as: :issuable, dependent: :destroy

  monetize :balance

  enum :classification, { asset: "asset", liability: "liability" }, validate: { allow_nil: true }

  scope :active, -> { where(is_active: true) }
  scope :assets, -> { where(classification: "asset") }
  scope :liabilities, -> { where(classification: "liability") }
  scope :alphabetically, -> { order(:name) }
  scope :ungrouped, -> { where(institution_id: nil) }

  delegated_type :accountable, types: Accountable::TYPES, dependent: :destroy

  accepts_nested_attributes_for :accountable

  delegate :value, :series, to: :accountable

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

    def create_with_optional_start_balance!(attributes:, start_date: nil, start_balance: nil)
      transaction do
        attributes[:accountable_attributes] ||= {} # Ensure accountable is created
        account = new(attributes)

        # Always initialize an account with a valuation entry to begin tracking value history
        account.entries.build \
          date: Date.current,
          amount: account.balance,
          currency: account.currency,
          entryable: Account::Valuation.new

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
  end

  def original_balance
    balance_amount = balances.chronological.first&.balance || balance
    Money.new(balance_amount, currency)
  end

  def owns_ticker?(ticker)
    security_id = Security.find_by(ticker: ticker)&.id
    entries.account_trades
           .joins("JOIN account_trades ON account_entries.entryable_id = account_trades.id")
           .where(account_trades: { security_id: security_id }).any?
  end

  def favorable_direction
    classification == "asset" ? "up" : "down"
  end

  def update_with_sync!(attributes)
    transaction do
      update!(attributes)
      update_balance!(attributes[:balance]) if attributes[:balance]
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
        amount: balance,
        currency: currency,
        entryable: Account::Valuation.new
    end
  end

  def holding_qty(security, date: Date.current)
    entries.account_trades
           .joins("JOIN account_trades ON account_entries.entryable_id = account_trades.id")
           .where(account_trades: { security_id: security.id })
           .where("account_entries.date <= ?", date)
           .sum("account_trades.qty")
  end
end
