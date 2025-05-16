class SimpleFinRateLimit < ApplicationRecord
  validates :date, presence: true
  validates :call_count, numericality: { greater_than_or_equal_to: 0 }
end
