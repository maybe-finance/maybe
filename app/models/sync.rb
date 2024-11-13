class Sync < ApplicationRecord
  belongs_to :syncable, polymorphic: true
  belongs_to :parent_sync, class_name: "Sync", optional: true

  has_many :child_syncs, class_name: "Sync", foreign_key: :parent_sync_id

  enum :status, { pending: "pending", syncing: "syncing", completed: "completed", failed: "failed" }

  scope :ordered, -> { order(created_at: :desc) }

  def perform
    start!

    syncable.sync_data(self)

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

      broadcast_append_to(
        [ family, :notifications ],
        target: "notification-tray",
        partial: "shared/notification",
        locals: { id: id, type: "processing", message: "Syncing account balances" }
      ) unless parent_sync.present?
    end

    def complete!
      update! status: :completed, last_ran_at: Time.current
      broadcast_result unless parent_sync.present?
    end

    def fail!(error)
      update! status: :failed, error: error.message, last_ran_at: Time.current

      broadcast_result(refresh: false) unless parent_sync.present?

      broadcast_append_to(
        [ family, :notifications ],
        target: "notification-tray",
        partial: "shared/notification",
        locals: { id: id, type: "alert", message: "Something went wrong while syncing your data." }
      ) unless parent_sync.present?
    end

    def broadcast_result(refresh: true)
      sleep 2 # Artificial delay for user experience
      broadcast_remove_to family, :notifications, target: id
      family.broadcast_refresh if refresh
    end
end
