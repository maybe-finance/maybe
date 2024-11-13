class SyncJob < ApplicationJob
  queue_as :default

  def perform(sync)
    sync.perform
  end
end
