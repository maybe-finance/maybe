class ValuationsController < ApplicationController
  before_action :authenticate_user!

  def create
    @account = Current.family.accounts.find(params[:account_id])

    # TODO: handle STI once we allow for different types of valuations
    @valuation = @account.valuations.new(valuation_params.merge(type: "Appraisal", currency: Current.family.currency))
    if @valuation.save
      redirect_to account_path(@account), notice: "Valuation created"
    else
      render :new, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotUnique
    flash.now[:error] = "Valuation already exists for this date"
    render :new, status: :unprocessable_entity
  end

  def show
    @valuation = Current.family.accounts.find(params[:account_id]).valuations.find(params[:id])
  end

  def edit
    @valuation = Valuation.find(params[:id])
  end

  def update
    @valuation = Valuation.find(params[:id])
    if @valuation.update(valuation_params)
      redirect_to account_path(@valuation.account), notice: "Valuation updated"
    else
      render :edit, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotUnique
    flash.now[:error] = "Valuation already exists for this date"
    render :edit, status: :unprocessable_entity
  end

  def destroy
    @valuation = Valuation.find(params[:id])
    account = @valuation.account
    @valuation.destroy
    redirect_to account_path(account), notice: "Valuation deleted"
  end

  def new
    @account = Current.family.accounts.find(params[:account_id])
    @valuation = @account.valuations.new
  end

  private
    def valuation_params
      params.require(:valuation).permit(:date, :value)
    end
end
