class Account::Trade < ApplicationRecord
  include Account::Entryable

  belongs_to :security
end
