class TransfersController < ApplicationController
  before_action :set_transfer, only: %i[destroy show update]

  def new
    @transfer = Transfer.new
  end

  def show
    @categories = Current.family.categories.expenses
  end

  def create
    from_account = Current.family.accounts.find(transfer_params[:from_account_id])
    to_account = Current.family.accounts.find(transfer_params[:to_account_id])

    @transfer = Transfer.from_accounts(
      from_account: from_account,
      to_account: to_account,
      date: transfer_params[:date],
      amount: transfer_params[:amount].to_d
    )

    if @transfer.save
      @transfer.sync_account_later

      flash[:notice] = t(".success")

      respond_to do |format|
        format.html { redirect_back_or_to transactions_path }
        redirect_target_url = request.referer || transactions_path
        format.turbo_stream { render turbo_stream: turbo_stream.action(:redirect, redirect_target_url) }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    Transfer.transaction do
      update_transfer_status
      update_transfer_details unless transfer_update_params[:status] == "rejected"
    end

    respond_to do |format|
      format.html { redirect_back_or_to transactions_url, notice: t(".success") }
      format.turbo_stream
    end
  end

  def destroy
    @transfer.destroy!
    redirect_back_or_to transactions_url, notice: t(".success")
  end

  private
    def set_transfer
      @transfer = Transfer.find(params[:id])

      raise ActiveRecord::RecordNotFound unless @transfer.belongs_to_family?(Current.family)
    end

    def transfer_params
      params.require(:transfer).permit(:from_account_id, :to_account_id, :amount, :date, :name, :excluded)
    end

    def transfer_update_params
      params.require(:transfer).permit(:notes, :status, :category_id)
    end

    def update_transfer_status
      if transfer_update_params[:status] == "rejected"
        @transfer.reject!
      elsif transfer_update_params[:status] == "confirmed"
        @transfer.confirm!
      end
    end

    def update_transfer_details
      @transfer.outflow_transaction.update!(category_id: transfer_update_params[:category_id])
      @transfer.update!(notes: transfer_update_params[:notes])
    end
end
