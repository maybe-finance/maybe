class Account::Holding < ApplicationRecord
  include Syncable

  belongs_to :account
  belongs_to :security

  class << self
    def sync(account, start_date: nil)
      Syncable::Response.new(success?: true)
    end
  end
end
