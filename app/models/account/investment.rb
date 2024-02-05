class Account::Investment < ApplicationRecord
  include Accountable

  def type_name
    "Investments"
  end
end
