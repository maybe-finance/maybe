class Account::ValuationsController < ApplicationController
  layout :with_sidebar

  before_action :set_account
  before_action :set_entry, only: %i[ show ]

  def index
    @entries = @account.entries.account_valuations.reverse_chronological
  end

  def show
  end

  private

    def set_account
      @account = Current.family.accounts.find(params[:account_id])
    end

    def set_entry
      @entry = @account.entries.find(params[:id])
    end
end
