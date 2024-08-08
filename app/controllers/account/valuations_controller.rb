class Account::ValuationsController < ApplicationController
  layout :with_sidebar

  before_action :set_account

  def new
    @entry = @account.entries.account_valuations.new
  end

  def index
    @entries = @account.entries.account_valuations.reverse_chronological
  end

  private

    def set_account
      @account = Current.family.accounts.find(params[:account_id])
    end
end
