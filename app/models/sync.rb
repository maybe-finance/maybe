class Sync < ApplicationRecord
  include AASM

  belongs_to :syncable, polymorphic: true

  belongs_to :parent, class_name: "Sync", optional: true
  has_many :children, class_name: "Sync", foreign_key: :parent_id, dependent: :destroy

  scope :ordered, -> { order(created_at: :desc) }
  scope :incomplete, -> { where(status: [ :pending, :syncing ]) }

  # Sync state machine
  aasm column: :status do
    state :pending, initial: true
    state :syncing
    state :completed
    state :failed

    event :start, after_commit: :handle_start do
      transitions from: :pending, to: :syncing
    end

    event :complete, after_commit: :handle_finalization do
      transitions from: :syncing, to: :completed
    end

    event :fail, after_commit: :handle_finalization do
      transitions from: :syncing, to: :failed
    end
  end

  def perform(start_date: nil)
    start!

    begin
      syncable.perform_sync(sync: self, start_date: start_date)
      attempt_finalization
    rescue => e
      fail!
      handle_error(e)
    end
  end

  # If the sync doesn't have any in-progress children, finalize it.
  def attempt_finalization
    Sync.transaction do
      lock!

      return unless all_children_finalized?

      if has_failed_children?
        fail!
      else
        complete!
      end
    end
  end

  private
    def has_failed_children?
      children.failed.any?
    end

    def all_children_finalized?
      children.incomplete.empty?
    end

    # Once sync finalizes, notify its parent and run its post-sync logic.
    def handle_finalization
      syncable.perform_post_sync

      if parent
        parent.attempt_finalization
      end
    end

    def handle_error(error)
      update!(error: error.message)
      Sentry.capture_exception(error) do |scope|
        scope.set_tags(sync_id: id)
      end
    end

    def handle_start
      update!(last_ran_at: Time.current)
    end
end
