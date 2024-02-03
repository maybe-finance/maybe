class Account::Loan < ApplicationRecord
  include Accountable

  def type_name
    "Loan"
  end
end
