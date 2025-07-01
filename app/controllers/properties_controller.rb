class PropertiesController < ApplicationController
  include AccountableResource

  before_action :set_property, only: [ :balances, :address, :update_balances, :update_address ]

  permitted_accountable_attributes(
    :id, :year_built, :area_unit, :area_value,
    address_attributes: [ :line1, :line2, :locality, :region, :country, :postal_code ]
  )

  def new
    @account = Current.family.accounts.build(accountable: Property.new)
  end

  def create
    @account = Current.family.accounts.create!(
      property_params.merge(currency: Current.family.currency, balance: 0)
    )

    redirect_to balances_property_path(@account)
  end

  def update
    if @account.update(property_params)
      @success_message = "Property details updated successfully."
      render :edit
    else
      @error_message = "Unable to update property details."
      render :edit, status: :unprocessable_entity
    end
  end

  def edit
  end

  def balances
  end

  def update_balances
    safe_params = params.require(:account).permit(:balance, :currency)
    @account.update!(safe_params)

    redirect_to address_property_path(@account)
  end

  def address
    @property = @account.property
    @property.address ||= Address.new
  end

  def update_address
    if @account.property.update(address_params)
      @success_message = "Address updated successfully."
      render :address
    else
      @error_message = "Unable to update address. Please check the required fields."
      render :address, status: :unprocessable_entity
    end
  end

  private
    def address_params
      params.require(:property)
            .permit(address_attributes: [ :line1, :line2, :locality, :region, :country, :postal_code ])
    end

    def property_params
      params.require(:account)
            .permit(:name, :subtype, :accountable_type, accountable_attributes: [ :id, :year_built, :area_unit, :area_value ])
    end

    def set_property
      @account = Current.family.accounts.find(params[:id])
      @property = @account.property
    end
end
