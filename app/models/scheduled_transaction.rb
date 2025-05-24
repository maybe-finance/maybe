class ScheduledTransaction < ApplicationRecord
  belongs_to :account
  belongs_to :category, optional: true
  belongs_to :merchant, optional: true
end
