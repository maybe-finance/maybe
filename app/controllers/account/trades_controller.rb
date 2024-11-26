class Account::TradesController < ApplicationController
  include EntryableResource

  private
    def build_entry
      Account::TradeBuilder.new(entry_params)
    end

    def entry_params
      params.require(:account_entry).permit(
        :account_id, :date, :amount, :currency, :qty, :price, :ticker, :type, :transfer_account_id
      ).tap do |params|
        account_id = params.delete(:account_id)
        params[:account] = Current.family.accounts.find(account_id)
      end
    end
end
