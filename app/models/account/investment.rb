class Account::Investment < ApplicationRecord
  include Accountable

  def self.type_name
    "Investments"
  end
end
