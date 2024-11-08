class SyncJob < ApplicationJob
  queue_as :default

  def perform(syncable, start_date: nil)
    syncable.sync(start_date: start_date)
  end
end
