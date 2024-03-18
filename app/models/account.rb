class Account < ApplicationRecord
  include Syncable
  include Monetizable

  validates :family, presence: true

  broadcasts_refreshes
  belongs_to :family
  has_many :balances, class_name: "AccountBalance"
  has_many :valuations
  has_many :transactions

  monetize :balance

  enum :status, { ok: "ok", syncing: "syncing", error: "error" }, validate: true

  scope :active, -> { where(is_active: true) }
  scope :assets, -> { where(classification: "asset") }
  scope :liabilities, -> { where(classification: "liability") }

  delegated_type :accountable, types: Accountable::TYPES, dependent: :destroy

  before_create :check_currency

  def self.ransackable_attributes(auth_object = nil)
    %w[name]
  end

  def balance_on(date)
    balances.where("date <= ?", date).order(date: :desc).first&.balance
  end

  def self.by_provider
    # TODO: When 3rd party providers are supported, dynamically load all providers and their accounts
    [ { name: "Manual accounts", accounts: all.order(balance: :desc).group_by(&:accountable_type) } ]
  end

  def self.some_syncing?
    exists?(status: "syncing")
  end

  def series(period = Period.all)
    TimeSeries.new(balances.in_period(period).map { |b| { date: b.date, value: b.balance_money } })
  end

  def self.by_group(period = Period.all)
    grouped_accounts = { assets: ValueGroup.new("Assets"), liabilities: ValueGroup.new("Liabilities") }

    Accountable.by_classification.each do |classification, types|
      types.each do |type|
        group = grouped_accounts[classification.to_sym].add_child_node(type)
        Accountable.from_type(type).includes(:account).find_each do |accountable|
          value_node = group.add_value_node(accountable.account)
          value_node.attach_series(accountable.account.series(period))
        end
      end
    end

    grouped_accounts
  end

  private
    def check_currency
      if self.currency == self.family.currency
        self.converted_balance = self.balance
        self.converted_currency = self.currency
      else
        self.converted_balance = ExchangeRate.convert(self.currency, self.family.currency, self.balance)
        self.converted_currency = self.family.currency
      end
    end
end
