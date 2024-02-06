class Account::Vehicle < ApplicationRecord
  include Accountable

  def self.type_name
    "Vehicle"
  end
end
