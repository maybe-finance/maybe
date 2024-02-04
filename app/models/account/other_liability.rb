class Account::OtherLiability < ApplicationRecord
  include Accountable

  def type_name
    "Other Liability"
  end
end
