class Merchant < ApplicationRecord
  has_many :transactions, dependent: :nullify, class_name: "Account::Transaction"

  validates :name, presence: true, uniqueness: true

  scope :alphabetically, -> { order(:name) }

  before_save :normalize_name

  class << self
    def normalize_name(name)
      name.downcase.strip.titleize
    end

    def find_or_create_by_normalized_name!(name)
      find_or_create_by!(name: normalize_name(name))
    end
  end

  private
    def normalize_name
      self.name = self.class.normalize_name(name)
    end
end
