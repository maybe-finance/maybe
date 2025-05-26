class Sync < ApplicationRecord
  # We run a cron that marks any syncs that have not been resolved in 24 hours as "stale"
  # Syncs often become stale when new code is deployed and the worker restarts
  STALE_AFTER = 24.hours

  # The max time that a sync will show in the UI (after 5 minutes)
  VISIBLE_FOR = 5.minutes

  include AASM

  Error = Class.new(StandardError)

  belongs_to :syncable, polymorphic: true

  belongs_to :parent, class_name: "Sync", optional: true
  has_many :children, class_name: "Sync", foreign_key: :parent_id, dependent: :destroy

  scope :ordered, -> { order(created_at: :desc) }
  scope :incomplete, -> { where("syncs.status IN (?)", %w[pending syncing]) }
  scope :visible, -> { incomplete.where("syncs.created_at > ?", VISIBLE_FOR.ago) }

  validate :window_valid

  # Sync state machine
  aasm column: :status, timestamps: true do
    state :pending, initial: true
    state :syncing
    state :completed
    state :failed
    state :stale

    after_all_transitions :log_status_change

    event :start, after_commit: :report_warnings do
      transitions from: :pending, to: :syncing
    end

    event :complete do
      transitions from: :syncing, to: :completed
    end

    event :fail do
      transitions from: :syncing, to: :failed
    end

    # Marks a sync that never completed within the expected time window
    event :mark_stale do
      transitions from: %i[pending syncing], to: :stale
    end
  end

  class << self
    def clean
      incomplete.where("syncs.created_at < ?", STALE_AFTER.ago).find_each(&:mark_stale!)
    end
  end

  def perform
    Rails.logger.tagged("Sync", id, syncable_type, syncable_id) do
      # This can happen on server restarts or if Sidekiq enqueues a duplicate job
      unless may_start?
        Rails.logger.warn("Sync #{id} is not in a valid state (#{aasm.from_state}) to start.  Skipping sync.")
        return
      end

      start!

      begin
        syncable.perform_sync(self)
      rescue => e
        fail!
        update(error: e.message)
        report_error(e)
      ensure
        finalize_if_all_children_finalized
      end
    end
  end

  # Finalizes the current sync AND parent (if it exists)
  def finalize_if_all_children_finalized
    Sync.transaction do
      lock!

      # If this is the "parent" and there are still children running, don't finalize.
      return unless all_children_finalized?

      if syncing?
        if has_failed_children?
          fail!
        else
          complete!
        end
      end

      # If we make it here, the sync is finalized.  Run post-sync, regardless of failure/success.
      perform_post_sync
    end

    # If this sync has a parent, try to finalize it so the child status propagates up the chain.
    parent&.finalize_if_all_children_finalized
  end

  private
    def log_status_change
      Rails.logger.info("changing from #{aasm.from_state} to #{aasm.to_state} (event: #{aasm.current_event})")
    end

    def has_failed_children?
      children.failed.any?
    end

    def all_children_finalized?
      children.incomplete.empty?
    end

    def perform_post_sync
      Rails.logger.info("Performing post-sync for #{syncable_type} (#{syncable.id})")
      syncable.perform_post_sync
      syncable.broadcast_sync_complete
    rescue => e
      Rails.logger.error("Error performing post-sync for #{syncable_type} (#{syncable.id}): #{e.message}")
      report_error(e)
    end

    def report_error(error)
      Sentry.capture_exception(error) do |scope|
        scope.set_tags(sync_id: id)
      end
    end

    def report_warnings
      todays_sync_count = syncable.syncs.where(created_at: Date.current.all_day).count

      if todays_sync_count > 10
        Sentry.capture_exception(
          Error.new("#{syncable_type} (#{syncable.id}) has exceeded 10 syncs today (count: #{todays_sync_count})"),
          level: :warning
        )
      end
    end

    def window_valid
      if window_start_date && window_end_date && window_start_date > window_end_date
        errors.add(:window_end_date, "must be greater than window_start_date")
      end
    end
end
