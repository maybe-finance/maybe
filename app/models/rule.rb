class Rule < ApplicationRecord
  belongs_to :family
  has_many :triggers, dependent: :destroy
  has_many :actions, dependent: :destroy

  validates :effective_date, presence: true
end
