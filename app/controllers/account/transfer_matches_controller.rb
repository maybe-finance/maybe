class Account::TransferMatchesController < ApplicationController
  before_action :set_entry

  def new
    @accounts = Current.family.accounts.alphabetically.where.not(id: @entry.account_id)
    @transfer_match_candidates = @entry.transfer_match_candidates
  end

  def create
    @transfer = build_transfer
    @transfer.save!
    @transfer.sync_account_later

    redirect_back_or_to transactions_path, notice: t(".success")
  end

  private
    def set_entry
      @entry = Current.family.entries.find(params[:transaction_id])
    end

    def transfer_match_params
      params.require(:transfer_match).permit(:method, :matched_entry_id, :target_account_id)
    end

    def build_transfer
      if transfer_match_params[:method] == "new"
        target_account = Current.family.accounts.find(transfer_match_params[:target_account_id])

        missing_transaction = Account::Transaction.new(
          entry: target_account.entries.build(
            amount: @entry.amount * -1,
            currency: @entry.currency,
            date: @entry.date,
            name: "Transfer from #{@entry.account.name}",
          )
        )

        Transfer.new(
          inflow_transaction: @entry.amount.positive? ? missing_transaction : @entry.account_transaction,
          outflow_transaction: @entry.amount.positive? ? @entry.account_transaction : missing_transaction,
          status: "confirmed"
        )
      else
        target_transaction = Current.family.entries.find(transfer_match_params[:matched_entry_id])

        Transfer.new(
          inflow_transaction: @entry.amount.negative? ? @entry.account_transaction : target_transaction.account_transaction,
          outflow_transaction: @entry.amount.negative? ? target_transaction.account_transaction : @entry.account_transaction,
          status: "confirmed"
        )
      end
    end
end
