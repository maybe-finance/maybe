class Account < ApplicationRecord
  belongs_to :family

  delegated_type :accountable, types: Accountable::TYPES, dependent: :destroy

  delegate :type_name, to: :accountable
  
  before_create :check_currency

  def check_currency
    if self.original_currency == self.family.currency
      self.converted_balance = self.original_balance
      self.converted_currency = self.original_currency
    else
      self.converted_balance = ExchangeRate.convert(self.original_currency, self.family.currency, self.original_balance)
      self.converted_currency = self.family.currency
    end
  end
  
  def self.by_type
    grouped = all.group_by { |account| account.accountable_type }
    total_account_value = all.sum(&:balance)

    grouped.map do |accountable_type, accounts|
      total_value = accounts.sum(&:balance)

      Account::Group.new(
        type: accountable_type.constantize,
        total_value:,
        percentage_held: (total_value / total_account_value) * 100
      )
    end
  end
end
