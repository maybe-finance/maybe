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
    sync_holdings

    complete!
  rescue StandardError => error
    fail! error
  end

  private

    def sync_balances
      syncer = Account::Balance::Syncer.new(account, start_date: start_date)

      syncer.run

      append_warnings(syncer.warnings)
    end

    def sync_holdings
      syncer = Account::Holding::Syncer.new(account, start_date: start_date)

      syncer.run

      append_warnings(syncer.warnings)
    end

    def append_warnings(new_warnings)
      update! warnings: warnings + new_warnings
    end

    def start!
      update! status: "syncing", last_ran_at: Time.now
      broadcast_start
    end

    def complete!
      update! status: "completed"
      broadcast_result type: "notice", message: "Sync complete"
    end

    def fail!(error)
      update! status: "failed", error: error.message
      broadcast_result type: "alert", message: error.message
    end

    def broadcast_start
      broadcast_append_to(
        [ account.family, :notifications ],
        target: "notification-tray",
        partial: "shared/notification",
        locals: { id: id, type: "processing", message: "Syncing account balances" }
      )
    end

    def broadcast_result(type:, message:)
      broadcast_remove_to account.family, :notifications, target: id # Remove persistent syncing notification
      broadcast_append_to(
        [ account.family, :notifications ],
        target: "notification-tray",
        partial: "shared/notification",
        locals: { type: type, message: message }
      )
    end
end
