class Transaction < ApplicationRecord
  belongs_to :account

  after_commit :sync_account

  private

    def sync_account
      self.account.sync
    end
end
