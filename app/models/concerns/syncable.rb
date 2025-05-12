module Syncable
  extend ActiveSupport::Concern

  included do
    has_many :syncs, as: :syncable, dependent: :destroy
  end

  def syncing?
    syncs.incomplete.any?
  end

  def sync_later(parent_sync: nil, window_start_date: nil, window_end_date: nil)
    new_sync = syncs.create!(parent: parent_sync, window_start_date: window_start_date, window_end_date: window_end_date)
    SyncJob.perform_later(new_sync)
  end

  def perform_sync(sync)
    syncer.perform_sync(sync)
  end

  def perform_post_sync
    syncer.perform_post_sync
  end

  def sync_error
    latest_sync&.error
  end

  def last_synced_at
    latest_sync&.completed_at
  end

  private
    def latest_sync
      syncs.ordered.first
    end

    def syncer
      self.class::Syncer.new(self)
    end
end
