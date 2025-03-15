class Security::Price < ApplicationRecord
  belongs_to :security

  validates :price, :currency, presence: true
end
