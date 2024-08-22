class Property < ApplicationRecord
  include Accountable

  has_one :address, as: :addressable, dependent: :destroy

  accepts_nested_attributes_for :address

  def area
    Measurement.new(area_value, area_unit)
  end
end
