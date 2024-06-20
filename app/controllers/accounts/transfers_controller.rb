class Accounts::TransfersController < ApplicationController
  layout "with_sidebar"

  before_action :set_transfer, only: :destroy

  def new
    @transfer = Account::Transfer.new
  end

  def create
    from_account = Current.family.accounts.find(transfer_params[:from_account_id])
    to_account = Current.family.accounts.find(transfer_params[:to_account_id])

    @transfer = Account::Transfer.build_from_accounts from_account, to_account, \
                                             date: transfer_params[:date],
                                             amount: transfer_params[:amount].to_d,
                                             currency: transfer_params[:currency],
                                             name: transfer_params[:name]

    if @transfer.save
      redirect_to transactions_path, notice: t(".success")
    else
      # TODO: this is not an ideal way to handle errors and should eventually be improved.
      # See: https://github.com/hotwired/turbo-rails/pull/367
      flash[:error] = @transfer.errors.full_messages.to_sentence
      redirect_to transactions_path
    end
  end

  def destroy
    @transfer.destroy_and_remove_marks!
    redirect_back_or_to transactions_url, notice: t(".success")
  end

  private

    def set_transfer
      @transfer = Account::Transfer.find(params[:id])
    end

    def transfer_params
      params.require(:account_transfer).permit(:from_account_id, :to_account_id, :amount, :currency, :date, :name)
    end
end
