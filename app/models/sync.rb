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
    def start!
      update! status: :syncing
    end

    def complete!
      update! status: :completed, last_ran_at: Time.current
    end

    def fail!(error)
      update! status: :failed, error: error.message, last_ran_at: Time.current
    end
end
