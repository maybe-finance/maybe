class Account::TradesController < ApplicationController
  layout :with_sidebar

  before_action :set_account

  def new
    @entry = @account.entries.account_trades.new
  end

  def index
    @entries = @account.entries.reverse_chronological.reject(&:account_valuation?)
  end

  def update
  end

  def create
  end

  private

    def set_account
      @account = Current.family.accounts.find(params[:account_id])
    end
end
