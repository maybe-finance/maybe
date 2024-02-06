class Account::Credit < ApplicationRecord
  include Accountable

  def self.type_name
    "Credit Card"
  end
end
