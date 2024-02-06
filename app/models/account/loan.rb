class Account::Loan < ApplicationRecord
  include Accountable

  def self.type_name
    "Loan"
  end
end
