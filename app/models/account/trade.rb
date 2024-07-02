class Account::Trade < ApplicationRecord
  belongs_to :account
  belongs_to :security
end
