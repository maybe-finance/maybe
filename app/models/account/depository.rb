class Account::Depository < ApplicationRecord
  include Accountable

  def type_name
    "Bank Accounts"
  end
end
