class Account::OtherLiability < ApplicationRecord
  include Accountable

  def self.type_name
    "Other Liability"
  end
end
