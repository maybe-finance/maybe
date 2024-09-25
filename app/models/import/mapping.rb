class Import::Mapping < ApplicationRecord
  FALLBACK_KEY = "_internal_unassigned"

  belongs_to :import
  belongs_to :mappable, polymorphic: true, optional: true

  scope :of_type, ->(type) { where(type: type.to_s) }

  class << self
    def find_with_fallback(key)
      find_by(key: key) || find_by(key: FALLBACK_KEY)
    end
  end
end
