module Account::Syncable
  extend ActiveSupport::Concern

  class_methods do
    def sync(start_date: nil)
      all.each { |a| a.sync_later(start_date: start_date) }
    end
  end

  def syncing?
    syncs.syncing.any?
  end

  def latest_sync_date
    syncs.where.not(last_ran_at: nil).pluck(:last_ran_at).max&.to_date
  end

  def needs_sync?
    latest_sync_date.nil? || latest_sync_date < Date.current
  end

  def sync_later(start_date: nil)
    AccountSyncJob.perform_later(self, start_date: start_date)
  end

  def sync(start_date: nil)
    Account::Sync.for(self, start_date: start_date).run
  end
end
