class Transactions::MerchantsController < ApplicationController
  before_action :set_merchant, only: %i[ edit update destroy ]

  def index
    @merchants = Current.family.transaction_merchants
  end

  def new
    @merchant = Transaction::Merchant.new
  end

  def create
    Current.family.transaction_merchants.create!(merchant_params)
    redirect_to transaction_merchants_path, notice: t(".success")
  end

  def edit
  end

  def update
    @merchant.update!(merchant_params)
    redirect_to transaction_merchants_path, notice: t(".success")
  end

  def destroy
    @merchant.destroy!
    redirect_to transaction_merchants_path, notice: t(".success")
  end

  private

  def set_merchant
    @merchant = Current.family.transaction_merchants.find(params[:id])
  end

  def merchant_params
    params.require(:transaction_merchant).permit(:name, :color)
  end
end
