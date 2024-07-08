class Account::Sync < ApplicationRecord
  class SyncError < StandardError
  end

  belongs_to :account

  enum :status, { pending: "pending", syncing: "syncing", completed: "completed", failed: "failed" }

  class << self
    def for(account, start_date: nil)
      create! account: account, start_date: start_date
    end

    def latest
      order(created_at: :desc).first
    end
  end

  def run
    start!

    sync_balances

    complete!
  rescue SyncError => error
    fail! error
  end

  private

    def sync_balances
      Account::Balance::Syncer.new(account, start_date: start_date).run
    end

    def start!
      update! status: "syncing"
    end

    def complete!
      update! status: "completed"
    end

    def fail!(error)
      update! status: "failed", error: error.message
    end
end
