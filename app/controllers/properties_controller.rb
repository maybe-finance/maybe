class PropertiesController < ApplicationController
  include AccountableResource, StreamExtensions

  before_action :set_property, only: [ :balances, :address, :update_balances, :update_address ]

  def new
    @account = Current.family.accounts.build(accountable: Property.new)
  end

  def create
    @account = Current.family.accounts.create!(
      property_params.merge(currency: Current.family.currency, balance: 0, status: "draft")
    )

    redirect_to balances_property_path(@account)
  end

  def update
    if @account.update(property_params)
      @success_message = "Property details updated successfully."

      if @account.active?
        render :edit
      else
        redirect_to balances_property_path(@account)
      end
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
    result = @account.set_current_balance(balance_params[:balance].to_d)

    if result.success?
      @success_message = "Balance updated successfully."

      if @account.active?
        render :balances
      else
        redirect_to address_property_path(@account)
      end
    else
      @error_message = result.error_message
      render :balances, status: :unprocessable_entity
    end
  end

  def address
    @property = @account.property
    @property.address ||= Address.new
  end

  def update_address
    if @account.property.update(address_params)
      if @account.draft?
        @account.activate!

        respond_to do |format|
          format.html { redirect_to account_path(@account) }
          format.turbo_stream { stream_redirect_to account_path(@account) }
        end
      else
        @success_message = "Address updated successfully."
        render :address
      end
    else
      @error_message = "Unable to update address. Please check the required fields."
      render :address, status: :unprocessable_entity
    end
  end

  private
    def balance_params
      params.require(:account).permit(:balance, :currency)
    end

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
