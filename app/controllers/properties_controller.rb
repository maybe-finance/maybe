class PropertiesController < ApplicationController
  include AccountableResource

  before_action :set_account, only: [ :show, :edit, :update, :destroy, :value, :address, :update_value, :update_address ]

  permitted_accountable_attributes(
    :id, :year_built, :area_unit, :area_value,
    address_attributes: [ :line1, :line2, :locality, :region, :country, :postal_code ]
  )

  def new
    @account = Current.family.accounts.build(
      currency: Current.family.currency,
      accountable: Property.new
    )
  end

  def create
    safe_params = params.require(:account)
                        .permit(:name, :subtype, :balance, :currency, :accountable_type, accountable_attributes: [ :year_built, :area_unit, :area_value ])

    @account = Current.family.accounts.create!(safe_params)

    redirect_to value_property_path(@account)
  end

  def update
    safe_params = params.require(:account)
                        .permit(:name, :subtype, :accountable_type, accountable_attributes: [ :year_built, :area_unit, :area_value ])

    @account.update!(safe_params)

    redirect_to value_property_path(@account)
  end

  def edit
    @account.accountable.address ||= Address.new
  end

  def value
  end

  def address
    @account.accountable.address ||= Address.new
  end

  def update_value
    safe_params = params.require(:account).permit(:balance, :currency)
    @account.update!(safe_params)

    redirect_to address_property_path(@account)
  end

  def update_address
    address_params = params.require(:account).permit(
      accountable_attributes: [
        :id,
        address_attributes: [ :line1, :line2, :locality, :region, :country, :postal_code ]
      ]
    )

    @account.update!(address_params)

    redirect_to @account, notice: "Property updated successfully!"
  end
end
