class Account::Credit < ApplicationRecord
  include Accountable

  def type_name
    "Credit Card"
  end
end
