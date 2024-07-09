module Account::Syncable
  extend ActiveSupport::Concern

  def sync_later(start_date: nil)
    AccountSyncJob.perform_later(self, start_date: start_date)
  end

  def sync(start_date: nil)
    Account::Sync.for(self, start_date: start_date).run
  end
end
