class Property < ApplicationRecord
  include Accountable

  has_one :address, as: :addressable, dependent: :destroy

  accepts_nested_attributes_for :address

  attribute :area_unit, :string, default: "sqft"

  def area
    Measurement.new(area_value, area_unit)
  end
end
