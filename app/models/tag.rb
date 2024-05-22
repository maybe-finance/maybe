class Tag < ApplicationRecord
  belongs_to :family
  has_many :taggings, dependent: :destroy
end
