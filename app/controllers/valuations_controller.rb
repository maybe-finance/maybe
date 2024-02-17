class ValuationsController < ApplicationController
  before_action :authenticate_user!, :set_account
  before_action :set_valuation, only: [ :show, :edit, :update, :destroy ]

  def create
    @valuation = @account.valuations.new(valuation_params.merge(type: "Appraisal", currency: Current.family.currency))
    if @valuation.save
      redirect_to account_path(@account), notice: "Valuation created"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
  end

  def update
  end

  def destroy
  end

  def edit
  end

  def new
    @valuation = @account.valuations.new
  end

  private
    def set_account
      @account = Current.family.accounts.find(params[:account_id])
    end

    def set_valuation
      @valuation = @account.valuations.find(params[:id])
    end

    def valuation_params
      params.require(:valuation).permit(:date, :value)
    end
end
