module Syncable
  extend ActiveSupport::Concern

  included do
    has_many :syncs, as: :syncable, dependent: :destroy
  end

  def syncing?
    syncs.syncing.any?
  end

  def last_synced_at
    syncs.ordered.first&.last_ran_at
  end

  def needs_sync?
    latest_sync&.last_ran_at.nil? || latest_sync.last_ran_at.to_date < Date.current
  end

  def sync_later(start_date: nil)
    SyncJob.perform_later(self, start_date: start_date)
  end

  def sync(start_date: nil, parent_sync: nil)
    syncs.create!(start_date: start_date, parent_sync: parent_sync).perform
  end

  def sync_data(sync_record)
    raise NotImplementedError, "Subclasses must implement the `sync_data` method"
  end

  private
    def latest_sync
      syncs.order(created_at: :desc).first
    end
end
