module Syncable
  extend ActiveSupport::Concern

  included do
    has_many :syncs, as: :syncable, dependent: :destroy
  end

  def syncing?
    raise NotImplementedError, "Subclasses must implement the syncing? method"
  end

  def sync_later(parent_sync: nil)
    Sync.transaction do
      with_lock do
        sync = self.syncs.incomplete.first

        unless sync
          sync = self.syncs.create!(parent: parent_sync)
        end

        SyncJob.perform_later(sync)

        sync
      end
    end
  end

  def perform_sync(sync)
    syncer.perform_sync(sync)
  end

  def perform_post_sync
    syncer.perform_post_sync
  end

  def broadcast_sync_complete
    sync_broadcaster.broadcast
  end

  def sync_error
    latest_sync&.error
  end

  def last_synced_at
    latest_sync&.completed_at
  end

  def last_sync_created_at
    latest_sync&.created_at
  end

  def needs_sync?
    data_synced_through.nil? || data_synced_through < Date.current
  end

  private
    def latest_sync
      syncs.ordered.first
    end

    def syncer
      self.class::Syncer.new(self)
    end

    def sync_broadcaster
      self.class::SyncCompleteEvent.new(self)
    end
end
