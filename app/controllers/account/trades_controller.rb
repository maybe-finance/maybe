class Account::TradesController < ApplicationController
  include EntryableResource

  permitted_entryable_attributes :id, :qty, :price

  private
    def build_entry
      Account::TradeBuilder.new(create_entry_params)
    end

    def create_entry_params
      params.require(:account_entry).permit(
        :account_id, :date, :amount, :currency, :qty, :price, :ticker, :manual_ticker, :type, :transfer_account_id
      ).tap do |params|
        account_id = params.delete(:account_id)
        params[:account] = Current.family.accounts.find(account_id)
      end
    end

    def update_entry_params
      return entry_params unless entry_params[:entryable_attributes].present?

      update_params = entry_params
      update_params = update_params.merge(entryable_type: "Account::Trade")

      qty = update_params[:entryable_attributes][:qty]
      price = update_params[:entryable_attributes][:price]

      if qty.present? && price.present?
        qty = update_params[:nature] == "inflow" ? -qty.to_d : qty.to_d
        update_params[:entryable_attributes][:qty] = qty
        update_params[:amount] = qty * price.to_d
      end

      update_params.except(:nature)
    end
end
