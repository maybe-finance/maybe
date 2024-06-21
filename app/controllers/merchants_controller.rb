class MerchantsController < ApplicationController
  layout "with_sidebar"

  before_action :set_merchant, only: %i[ edit update destroy ]

  def index
    @merchants = Current.family.merchants.alphabetically
  end

  def new
    @merchant = Merchant.new
  end

  def create
    Current.family.merchants.create!(merchant_params)
    redirect_to merchants_path, notice: t(".success")
  end

  def edit
  end

  def update
    @merchant.update!(merchant_params)
    redirect_to merchants_path, notice: t(".success")
  end

  def destroy
    @merchant.destroy!
    redirect_to merchants_path, notice: t(".success")
  end

  private

  def set_merchant
    @merchant = Current.family.merchants.find(params[:id])
  end

  def merchant_params
    params.require(:merchant).permit(:name, :color)
  end
end
