class Account::Vehicle < ApplicationRecord
  include Accountable

  def type_name
    "Vehicle"
  end
end
