class PropertiesController < ApplicationController
  include AccountableResource, StreamExtensions

  before_action :set_property, only: [ :edit, :update, :details, :update_details, :address, :update_address ]

  def new
    @account = Current.family.accounts.build(accountable: Property.new)
  end

  def create
    @account = Current.family.create_property_account!(
      name: property_params[:name],
      current_value: property_params[:current_estimated_value].to_d,
      purchase_price: property_params[:purchase_price].present? ? property_params[:purchase_price].to_d : nil,
      purchase_date: property_params[:purchase_date],
      currency: property_params[:currency] || Current.family.currency,
      draft: true
    )

    redirect_to details_property_path(@account)
  end

  def update
    form = Account::OverviewForm.new(
      account: @account,
      name: property_params[:name],
      currency: property_params[:currency],
      opening_balance: property_params[:purchase_price],
      opening_cash_balance: property_params[:purchase_price].present? ? "0" : nil,
      opening_date: property_params[:purchase_date],
      current_balance: property_params[:current_estimated_value],
      current_cash_balance: property_params[:current_estimated_value].present? ? "0" : nil
    )

    result = form.save

    if result.success?
      @success_message = "Property details updated successfully."

      if @account.active?
        render :edit
      else
        redirect_to details_property_path(@account)
      end
    else
      @error_message = result.error || "Unable to update property details."
      render :edit, status: :unprocessable_entity
    end
  end

  def edit
  end

  def details
  end

  def update_details
    if @account.update(details_params)
      @success_message = "Property details updated successfully."

      if @account.active?
        render :details
      else
        redirect_to address_property_path(@account)
      end
    else
      @error_message = "Unable to update property details."
      render :details, status: :unprocessable_entity
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
    def details_params
      params.require(:account)
            .permit(:subtype, accountable_attributes: [ :id, :year_built, :area_unit, :area_value ])
    end

    def address_params
      params.require(:property)
            .permit(address_attributes: [ :line1, :line2, :locality, :region, :country, :postal_code ])
    end

    def property_params
      params.require(:account)
            .permit(:name, :currency, :purchase_price, :purchase_date, :current_estimated_value,
                    :subtype, :accountable_type,
                    accountable_attributes: [ :id, :year_built, :area_unit, :area_value ])
    end

    def set_property
      @account = Current.family.accounts.find(params[:id])
      @property = @account.property
    end
end
