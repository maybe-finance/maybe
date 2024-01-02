class Portfolio < ApplicationRecord
  belongs_to :user
  has_many :holdings, dependent: :destroy

  validates :name, presence: true
end
