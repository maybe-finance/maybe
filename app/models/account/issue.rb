class Account::Issue < ApplicationRecord
  belongs_to :account

  before_create :set_priority

  scope :ordered, -> { order(:priority) }

  def default_priority
    3
  end

  def message
    raise NotImplementedError, "Subclasses must implement this method"
  end

  private

    def set_priority
      self.priority = default_priority
    end
end
