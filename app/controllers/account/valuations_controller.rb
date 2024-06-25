class Account::ValuationsController < ApplicationController
  before_action :set_account
  before_action :set_valuation, only: %i[ show edit update destroy ]

  def new
    @valuation = Account::Valuation.new
    @entry = @account.entries.build entryable: @valuation
  end

  def show
  end

  def create
    @entry = @account.entries.build(entry_params.merge(entryable: Account::Valuation.new))

    if @entry.save
      @entry.sync_account_later
      redirect_to account_path(@account), notice: "Valuation created"
    else
      # TODO: this is not an ideal way to handle errors and should eventually be improved.
      # See: https://github.com/hotwired/turbo-rails/pull/367
      flash[:error] = @entry.errors.full_messages.to_sentence
      redirect_to account_path(@account)
    end
  end

  def edit
  end

  def update
    if @entry.update(entry_params)
      @entry.sync_account_later
      redirect_to account_path(@account), notice: t(".success")
    else
      # TODO: this is not an ideal way to handle errors and should eventually be improved.
      # See: https://github.com/hotwired/turbo-rails/pull/367
      flash[:error] = @entry.errors.full_messages.to_sentence
      redirect_to account_path(@account)
    end
  end

  def destroy
    @entry.destroy!
    @entry.sync_account_later

    redirect_to account_path(@account), notice: t(".success")
  end

  private

    def set_account
      @account = Current.family.accounts.find(params[:account_id])
    end

    def set_valuation
      @valuation = @account.valuations.find(params[:id])
      @entry = @valuation.entry
    end

    def entry_params
      params.require(:account_entry).permit(:date, :amount, :currency)
    end
end
