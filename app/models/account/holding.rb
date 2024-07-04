class Account::Holding < ApplicationRecord
  include Syncable

  belongs_to :account
  belongs_to :security
end
