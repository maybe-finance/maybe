class Account::ValuationsController < ApplicationController
  before_action :set_account
  before_action :set_valuation, only: %i[ show edit update destroy ]

  def new
    @valuation = @account.valuations.new
  end

  def show
  end

  def create
    @valuation = @account.valuations.build(valuation_params)

    if @valuation.save
      @valuation.sync_account_later
      redirect_to account_path(@account), notice: "Valuation created"
    else
      # TODO: this is not an ideal way to handle errors and should eventually be improved.
      # See: https://github.com/hotwired/turbo-rails/pull/367
      flash[:error] = @valuation.errors.full_messages.to_sentence
      redirect_to account_path(@account)
    end
  end

  def edit
  end

  def update
    if @valuation.update(valuation_params)
      @valuation.sync_account_later
      redirect_to account_path(@account), notice: t(".success")
    else
      # TODO: this is not an ideal way to handle errors and should eventually be improved.
      # See: https://github.com/hotwired/turbo-rails/pull/367
      flash[:error] = @valuation.errors.full_messages.to_sentence
      redirect_to account_path(@account)
    end
  end

  def destroy
    @valuation.destroy!
    @valuation.sync_account_later

    redirect_to account_path(@account), notice: t(".success")
  end

  private

    def set_account
      @account = Current.family.accounts.find(params[:account_id])
    end

    def set_valuation
      @valuation = @account.valuations.find(params[:id])
    end

    def valuation_params
      params.require(:account_valuation).permit(:date, :value, :currency)
    end
end
