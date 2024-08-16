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

    account.resolve_stale_issues

    sync_balances
    sync_holdings

    complete!
  rescue StandardError => error
    account.observe_unknown_issue(error)
    fail! error

    raise error if Rails.env.development?
  end

  private

    def sync_balances
      Account::Balance::Syncer.new(account, start_date: start_date).run
    end

    def sync_holdings
      Account::Holding::Syncer.new(account, start_date: start_date).run
    end

    def start!
      update! status: "syncing", last_ran_at: Time.now
      broadcast_start
    end

    def complete!
      update! status: "completed"

      if account.has_issues?
        broadcast_result type: "alert", message: account.highest_priority_issue.title
      else
        broadcast_result type: "notice", message: "Sync complete"
      end
    end

    def fail!(error)
      update! status: "failed", error: error.message
      broadcast_result type: "alert", message: I18n.t("account.sync.failed")
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

      account.family.broadcast_refresh
    end
end
