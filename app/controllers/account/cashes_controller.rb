class Account::CashesController < ApplicationController
  layout :with_sidebar

  def index
    @account = Current.family.accounts.find(params[:account_id])
  end
end
