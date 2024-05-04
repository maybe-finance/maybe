class Transaction::Tag < ApplicationRecord
  belongs_to :family

  validates :name, :family, presence: true
  scope :alphabetically, -> { order(:name) }

  def self.ransackable_attributes(auth_object = nil)
    %w[name id]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[]
  end
end
