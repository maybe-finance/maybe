module Syncable
  extend ActiveSupport::Concern

  included do
    has_many :syncs, as: :syncable, dependent: :destroy
  end

  def syncing?
    syncs.where(status: [ :syncing, :pending ]).any?
  end

  def sync_later(start_date: nil, parent_sync: nil)
    new_sync = syncs.create!(start_date: start_date, parent: parent_sync)
    SyncJob.perform_later(new_sync)
  end

  def sync(start_date: nil)
    syncs.create!(start_date: start_date).perform
  end

  def sync_data(sync, start_date: nil)
    raise NotImplementedError, "Subclasses must implement the `sync_data` method"
  end

  def post_sync(sync)
    # no-op, syncable can optionally provide implementation
  end

  def sync_error
    latest_sync.error
  end

  private
    def latest_sync
      syncs.order(created_at: :desc).first
    end
end
