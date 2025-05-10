class Sync < ApplicationRecord
  Error = Class.new(StandardError)

  belongs_to :syncable, polymorphic: true

  belongs_to :parent, class_name: "Sync", optional: true
  has_many :children, class_name: "Sync", foreign_key: :parent_id, dependent: :destroy

  enum :status, { pending: "pending", syncing: "syncing", completed: "completed", failed: "failed" }

  scope :ordered, -> { order(created_at: :desc) }

  def child?
    parent_id.present?
  end

  def perform
    Rails.logger.tagged("Sync", id, syncable_type, syncable_id) do
      start!

      begin
        syncer.perform_sync(self, start_date: start_date)

        unless has_pending_child_syncs?
          complete!
          Rails.logger.info("Sync completed, starting post-sync")
          syncer.perform_post_sync(self)
          Rails.logger.info("Post-sync completed")
        end
      rescue StandardError => error
        fail! error, report_error: true
      ensure
        notify_parent_of_completion! if has_parent?
      end
    end
  end

  def handle_child_completion_event
    Sync.transaction do
      # We need this to ensure 2 child syncs don't update the parent at the exact same time with different results
      # and cause the sync to hang in "syncing" status indefinitely
      self.lock!

      unless has_pending_child_syncs?
        if has_failed_child_syncs?
          fail!(Error.new("One or more child syncs failed"))
        else
          complete!
        end

        # If this sync is both a child and a parent, we need to notify the parent of completion
        notify_parent_of_completion! if has_parent?

        syncer.perform_post_sync(self)
      end
    end
  end

  private
    def syncer
      "#{syncable_type}::Syncer".constantize.new(syncable)
    end

    def has_pending_child_syncs?
      children.where(status: [ :pending, :syncing ]).any?
    end

    def has_failed_child_syncs?
      children.where(status: :failed).any?
    end

    def has_parent?
      parent_id.present?
    end

    def notify_parent_of_completion!
      parent.handle_child_completion_event
    end

    def start!
      Rails.logger.info("Starting sync")
      update! status: :syncing
    end

    def complete!
      Rails.logger.info("Sync completed")
      update! status: :completed, last_ran_at: Time.current
    end

    def fail!(error, report_error: false)
      Rails.logger.error("Sync failed: #{error.message}")

      if report_error
        Sentry.capture_exception(error) do |scope|
          scope.set_context("sync", { id: id, syncable_type: syncable_type, syncable_id: syncable_id })
          scope.set_tags(sync_id: id)
        end
      end

      update!(
        status: :failed,
        error: error.message,
        last_ran_at: Time.current
      )
    end
end
