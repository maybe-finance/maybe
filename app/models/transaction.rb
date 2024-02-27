class Transaction < ApplicationRecord
  belongs_to :account

  after_commit :sync_account

  private

    def sync_account
      self.account.sync(start_date: self.date)
    end
end
