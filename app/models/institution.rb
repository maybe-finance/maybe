class Institution < ApplicationRecord
  belongs_to :family
  has_many :accounts, dependent: :nullify
  has_one_attached :logo
end
