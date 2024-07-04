class Account::Sync < ApplicationRecord
  belongs_to :account

  enum :status, { pending: "pending", syncing: "syncing", completed: "completed", failed: "failed" }

  class << self
    def for(account, start_date = nil)
      create! account: account, start_date: start_date
    end

    def latest
      order(created_at: :desc).first
    end
  end

  def start(syncables, start_date = nil)
    raise "Sync has already been run" unless status == "pending"

    start!

    syncables.each do |syncable|
      sync_result = syncable.sync(account, start_date: start_date)

      process_sync(sync_result)
    end

    complete!
  rescue Syncable::Error => error
    fail! error
  end

  private

    def process_sync(sync_response)
      unless sync_response.success?
        raise sync_response.error
      end

      append_warnings(sync_response.warnings) if sync_response.warnings
    end

    def append_warnings(new_warnings)
      update! warnings: warnings + new_warnings.map(&:message)
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
