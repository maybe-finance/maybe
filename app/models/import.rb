class Import < ApplicationRecord
  belongs_to :account
  has_many :rows, dependent: :destroy
end
