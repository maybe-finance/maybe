class PropertiesController < ApplicationController
  include AccountableResource

  permitted_accountable_attributes(
    :id, :year_built, :area_unit, :area_value,
    address_attributes: [ :line1, :line2, :locality, :region, :country, :postal_code ]
  )

  def new
    @account = Current.family.accounts.build(
      currency: Current.family.currency,
      accountable: Property.new(
        address: Address.new
      )
    )
  end

  def edit
    @account.accountable.address ||= Address.new
  end
end
