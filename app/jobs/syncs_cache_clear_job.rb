class SyncsCacheClearJob < ApplicationJob
  queue_as :low_priority

  def perform(family)
    syncs = family.syncs
    ActiveRecord::Base.transaction do
      syncs
        .where(status: [ "pending", "syncing" ])
        .update_all(status: "failed")
    end
  end
end
