class Account < ApplicationRecord
  belongs_to :family

  scope :depository, -> { where(type: 'Depository') }
end
