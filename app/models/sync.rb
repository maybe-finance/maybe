class Sync < ApplicationRecord
  belongs_to :syncable, polymorphic: true

  enum :status, { pending: "pending", syncing: "syncing", completed: "completed", failed: "failed" }

  scope :ordered, -> { order(created_at: :desc) }

  def perform
    Rails.logger.tagged("Sync", id, syncable_type, syncable_id) do
      start!

      begin
        data = syncable.sync_data(start_date: start_date)
        update!(data: data) if data
        complete!
      rescue StandardError => error
        fail! error
        raise error if Rails.env.development?
      ensure
        Rails.logger.info("Sync completed, starting post-sync")

        syncable.post_sync

        Rails.logger.info("Post-sync completed")
      end
    end
  end

  private
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
      end

      update!(
        status: :failed,
        error: error.message,
        last_ran_at: Time.current
      )
    end
end
