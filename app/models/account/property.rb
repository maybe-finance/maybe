class Account::Property < ApplicationRecord
  include Accountable

  def self.type_name
    "Real Estate"
  end
end
