class TransferMatchesController < ApplicationController
  before_action :set_entry

  def new
    @accounts = Current.family.accounts.visible.alphabetically.where.not(id: @entry.account_id)
    @transfer_match_candidates = @entry.transaction.transfer_match_candidates
  end

  def create
    @transfer = build_transfer
    Transfer.transaction do
      @transfer.save!
      @transfer.outflow_transaction.update!(kind: Transfer.kind_for_account(@transfer.outflow_transaction.entry.account))
      @transfer.inflow_transaction.update!(kind: "funds_movement")
    end

    @transfer.sync_account_later

    redirect_back_or_to transactions_path, notice: "Transfer created"
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

        missing_transaction = Transaction.new(
          entry: target_account.entries.build(
            amount: @entry.amount * -1,
            currency: @entry.currency,
            date: @entry.date,
            name: "Transfer to #{@entry.amount.negative? ? @entry.account.name : target_account.name}",
          )
        )

        transfer = Transfer.find_or_initialize_by(
          inflow_transaction: @entry.amount.positive? ? missing_transaction : @entry.transaction,
          outflow_transaction: @entry.amount.positive? ? @entry.transaction : missing_transaction
        )
        transfer.status = "confirmed"
        transfer
      else
        target_transaction = Current.family.entries.find(transfer_match_params[:matched_entry_id])

        transfer = Transfer.find_or_initialize_by(
          inflow_transaction: @entry.amount.negative? ? @entry.transaction : target_transaction.transaction,
          outflow_transaction: @entry.amount.negative? ? target_transaction.transaction : @entry.transaction
        )
        transfer.status = "confirmed"
        transfer
      end
    end
end
