class Account < ApplicationRecord
  include Syncable

  broadcasts_refreshes
  belongs_to :family
  has_many :balances, class_name: "AccountBalance"
  has_many :valuations
  has_many :transactions

  delegated_type :accountable, types: Accountable::TYPES, dependent: :destroy

  before_create :check_currency

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
