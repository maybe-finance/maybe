class Account < ApplicationRecord
  include Syncable

  broadcasts_refreshes
  belongs_to :family
  has_many :balances, class_name: "AccountBalance"
  has_many :valuations
  has_many :transactions

  delegated_type :accountable, types: Accountable::TYPES, dependent: :destroy

  delegate :type_name, to: :accountable
  before_create :check_currency

  def classification
    classifications = {
      "Account::Depository" => :asset,
      "Account::Investment" => :asset,
      "Account::Property" => :asset,
      "Account::Vehicle" => :asset,
      "Account::OtherAsset" => :asset,
      "Account::Loan" => :liability,
      "Account::Credit" => :liability,
      "Account::OtherLiability" => :liability
    }

    classifications[accountable_type]
  end

  def balance_series(period)
    MoneySeries.new(
      balances.in_period(period).order(:date),
      { trend_type: classification }
    )
  end

  def valuation_series
    MoneySeries.new(
      valuations.order(:date),
      { trend_type: classification, amount_accessor: :value }
    )
  end

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
