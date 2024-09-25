class Import::Mapping < ApplicationRecord
  belongs_to :import
  belongs_to :mappable, polymorphic: true, optional: true

  scope :of_type, ->(type) { where(type: type.to_s) }
end
