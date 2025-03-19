class SyncJob < ApplicationJob
  queue_as :high_priority

  def perform(sync)
    sleep 1 # simulate work for faster jobs
    sync.perform
  end
end
