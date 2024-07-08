class Account::Sync < ApplicationRecord
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
  rescue StandardError => error
    fail! error
  end

  private

    def sync_balances
      syncer = Account::Balance::Syncer.new(account, start_date: start_date).run

      append_warnings(syncer.warnings)

      raise syncer.error if syncer.error
    end

    def append_warnings(new_warnings)
      update! warnings: warnings + new_warnings
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
