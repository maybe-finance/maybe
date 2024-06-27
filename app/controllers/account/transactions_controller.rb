class Account::TransactionsController < ApplicationController
  layout "with_sidebar"

  before_action :set_account

  def index
    @transaction_entries = @account.entries.account_transactions.reverse_chronological
  end

  private

    def set_account
      @account = Current.family.accounts.find(params[:account_id])
    end
end
