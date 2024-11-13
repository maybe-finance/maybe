class Sync < ApplicationRecord
  belongs_to :syncable, polymorphic: true

  enum :status, { pending: "pending", syncing: "syncing", completed: "completed", failed: "failed" }

  scope :ordered, -> { order(created_at: :desc) }

  def perform
    start!

    transaction do
      syncable.sync_data(start_date: start_date)
    end

    complete!
  rescue StandardError => error
    fail! error
    raise error if Rails.env.development?
  end

  private
    def family
      syncable.is_a?(Family) ? syncable : syncable.family
    end

    def start!
      update! status: :syncing
    end

    def complete!
      update! status: :completed, last_ran_at: Time.current

      family.broadcast_refresh
    end

    def fail!(error)
      update! status: :failed, error: error.message, last_ran_at: Time.current

      family.broadcast_refresh
    end
end
