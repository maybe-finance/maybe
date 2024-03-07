class Transaction < ApplicationRecord
  belongs_to :account
  belongs_to :category, optional: true

  after_commit :sync_account

  private

    def sync_account
      self.account.sync_later
    end
end
