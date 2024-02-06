class Account::Depository < ApplicationRecord
  include Accountable

  def self.type_name
    "Bank Accounts"
  end
end
