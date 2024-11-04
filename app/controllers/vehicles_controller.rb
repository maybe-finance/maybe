class VehiclesController < ApplicationController
  include AccountableResource

  permitted_accountable_attributes(
    :id, :make, :model, :year, :mileage_value, :mileage_unit
  )
end
