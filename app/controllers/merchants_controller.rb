class MerchantsController < ApplicationController
  before_action :set_merchant, only: %i[edit update destroy]

  def index
    @merchants = Current.family.merchants.alphabetically

    render layout: "settings"
  end

  def new
    @merchant = Merchant.new
  end

  def create
    @merchant = Current.family.merchants.new(merchant_params)

    if @merchant.save
      redirect_to merchants_path, notice: t(".success")
    else
      redirect_to merchants_path, alert: t(".error", error: @merchant.errors.full_messages.to_sentence)
    end
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
