class Import::Row < ApplicationRecord
  belongs_to :import

  scope :ordered, -> { order(created_at: :desc) }

  def import!
    raise NotImplementedError, "Import row must implement import!"
  end
end
