class Account::ValuationsController < ApplicationController
  before_action :set_account
  before_action :set_valuation, only: %i[ edit update destroy ]

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

  def show
    @valuation = Current.family.accounts.find(params[:account_id]).valuations.find(params[:id])
  end

  def edit
  end

  def update
    sync_start_date = [ @valuation.date, Date.parse(valuation_params[:date]) ].compact.min
    if @valuation.update(valuation_params)
      @valuation.account.sync_later(sync_start_date)

      redirect_to account_path(@valuation.account), notice: "Valuation updated"
    else
      render :edit, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotUnique
    flash.now[:error] = "Valuation already exists for this date"
    render :edit, status: :unprocessable_entity
  end

  def destroy
    @account = @valuation.account
    sync_start_date = @account.valuations.where("date < ?", @valuation.date).order(date: :desc).first&.date
    @valuation.destroy!
    @account.sync_later(sync_start_date)

    respond_to do |format|
      format.html { redirect_to account_path(@account), notice: "Valuation deleted" }
      format.turbo_stream
    end
  end

  def new
    @account = Current.family.accounts.find(params[:account_id])
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
      params.require(:account_valuation).permit(:date, :value, :currency)
    end
end
