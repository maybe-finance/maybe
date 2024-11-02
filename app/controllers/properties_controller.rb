class PropertiesController < ApplicationController
  include AccountActions

  permitted_accountable_attributes(
    :id, :year_built, :area_unit, :area_value,
    address_attributes: [ :line1, :line2, :locality, :region, :country, :postal_code ]
  )
end
