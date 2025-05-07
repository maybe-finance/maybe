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
        data = syncable.sync_data(self, start_date: start_date)
        update!(data: data) if data

        complete! unless has_pending_child_syncs?

        unless has_pending_child_syncs?
          Rails.logger.info("Sync completed, starting post-sync")
          syncable.post_sync(self)
          Rails.logger.info("Post-sync completed")
        end
      rescue StandardError => error
        fail! error
        raise error if Rails.env.development?
      ensure
        if has_parent?
          Rails.logger.info("notifying parent sync id=#{parent_id} of completion")
          notify_parent_of_completion!
        end
      end
    end
  end

  def handle_child_completion_event
    Sync.transaction do
      # We need this to ensure 2 child syncs don't update the parent at the exact same time with different results
      # and cause the sync to hang in "syncing" status indefinitely
      self.lock!

      unless has_pending_child_syncs?
        complete!
        syncable.post_sync(self)
      end
    end
  end

  private
    def has_pending_child_syncs?
      children.where(status: [ :pending, :syncing ]).any?
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

    def fail!(error)
      Rails.logger.error("Sync failed: #{error.message}")

      Sentry.capture_exception(error) do |scope|
        scope.set_context("sync", { id: id, syncable_type: syncable_type, syncable_id: syncable_id })
        scope.set_tags(sync_id: id)
      end

      update!(
        status: :failed,
        error: error.message,
        last_ran_at: Time.current
      )
    end
end
