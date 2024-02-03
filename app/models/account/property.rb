class Account::Property < ApplicationRecord
  include Accountable

  def type_name
    "Real Estate"
  end
end
