class SyncJob < ApplicationJob
  queue_as :high_priority

  def perform(sync)
    sync.perform
  end
end
