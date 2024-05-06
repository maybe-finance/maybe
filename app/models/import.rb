class Import < ApplicationRecord
  belongs_to :account
  has_many :rows, dependent: :destroy

  scope :ordered, -> { order(:created_at) }
end
