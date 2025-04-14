class Merchant < ApplicationRecord
  has_many :transactions, dependent: :nullify, class_name: "Transaction"
  belongs_to :family

  validates :name, :color, :family, presence: true
  validates :name, uniqueness: { scope: :family }

  scope :alphabetically, -> { order(:name) }

  COLORS = %w[#e99537 #4da568 #6471eb #db5a54 #df4e92 #c44fe9 #eb5429 #61c9ea #805dee #6ad28a]
end
