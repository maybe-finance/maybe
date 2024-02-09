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
      # TODO: Run a background job to convert the balance
    end
  end
end
