class SyncCleanerJob < ApplicationJob
  queue_as :scheduled

  def perform
    Sync.clean
  end
end
