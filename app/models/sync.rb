class Sync < ApplicationRecord
  belongs_to :syncable, polymorphic: true

  enum :status, { pending: "pending", syncing: "syncing", completed: "completed", failed: "failed" }

  scope :ordered, -> { order(created_at: :desc) }

  def perform
    start!

    begin
      data = syncable.sync_data(start_date: start_date)
      update!(data: data) if data
      complete!
    rescue StandardError => error
      fail! error
      raise error if Rails.env.development?
    ensure
      syncable.post_sync
    end
  end

  private
    def start!
      update! status: :syncing
    end

    def complete!
      update! status: :completed, last_ran_at: Time.current
    end

    def fail!(error)
      Sentry.capture_exception(error) do |scope|
        scope.set_context("sync", { id: id })
      end

      update! status: :failed, error: error.message, last_ran_at: Time.current
    end
end
