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
        syncable.sync_data(self, start_date: start_date)

        complete!
        Rails.logger.info("Sync completed, starting post-sync")
        syncable.post_sync(self)
        Rails.logger.info("Post-sync completed")
      rescue StandardError => error
        fail! error, report_error: true
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
