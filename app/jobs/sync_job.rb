class SyncJob < ApplicationJob
  queue_as :latency_medium

  def perform(sync)
    sync.perform
  end
end
