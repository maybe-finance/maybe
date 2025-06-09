class FamilyMerchantsController < ApplicationController
  before_action :set_merchant, only: %i[edit update destroy]

  def index
    @breadcrumbs = [ [ "Home", root_path ], [ "Merchants", nil ] ]

    @family_merchants = Current.family.merchants.alphabetically

    render layout: "settings"
  end

  def new
    @family_merchant = FamilyMerchant.new(family: Current.family)
  end

  def create
    @family_merchant = FamilyMerchant.new(merchant_params.merge(family: Current.family))

    if @family_merchant.save
      respond_to do |format|
        format.html { redirect_to family_merchants_path, notice: t(".success") }
        format.turbo_stream { render turbo_stream: turbo_stream.action(:redirect, family_merchants_path) }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    @family_merchant.update!(merchant_params)
    respond_to do |format|
      format.html { redirect_to family_merchants_path, notice: t(".success") }
      format.turbo_stream { render turbo_stream: turbo_stream.action(:redirect, family_merchants_path) }
    end
  end

  def destroy
    @family_merchant.destroy!
    redirect_to family_merchants_path, notice: t(".success")
  end

  private
    def set_merchant
      @family_merchant = Current.family.merchants.find(params[:id])
    end

    def merchant_params
      params.require(:family_merchant).permit(:name, :color)
    end
end
