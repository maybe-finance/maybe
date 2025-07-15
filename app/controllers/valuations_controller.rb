class ValuationsController < ApplicationController
  include EntryableResource, StreamExtensions

  def confirm_create
    @account = Current.family.accounts.find(params.dig(:entry, :account_id))
    @entry = @account.entries.build(entry_params.merge(currency: @account.currency))

    render :confirm_create
  end

  def confirm_update
    @entry = Current.family.entries.find(params[:id])
    @account = @entry.account
    @entry.assign_attributes(entry_params.merge(currency: @account.currency))

    render :confirm_update
  end

  def create
    account = Current.family.accounts.find(params.dig(:entry, :account_id))
    result = perform_balance_update(account, entry_params.merge(currency: account.currency))

    if result.success?
      @success_message = result.updated? ? "Balance updated" : "No changes made. Account is already up to date."

      respond_to do |format|
        format.html { redirect_back_or_to account_path(account), notice: @success_message }
        format.turbo_stream { stream_redirect_back_or_to(account_path(account), notice: @success_message) }
      end
    else
      @error_message = result.error_message
      render :new, status: :unprocessable_entity
    end
  end

  def update
    result = perform_balance_update(@entry.account, entry_params.merge(currency: @entry.currency, existing_valuation_id: @entry.id))

    if result.success?
      @entry.reload

      respond_to do |format|
        format.html { redirect_back_or_to account_path(@entry.account), notice: result.updated? ? "Balance updated" : "No changes made. Account is already up to date." }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(
              dom_id(@entry, :header),
              partial: "valuations/header",
              locals: { entry: @entry }
            ),
            turbo_stream.replace(@entry)
          ]
        end
      end
    else
      @error_message = result.error_message
      render :show, status: :unprocessable_entity
    end
  end

  private
    def entry_params
      params.require(:entry)
            .permit(:date, :amount, :currency, :notes)
    end

    def perform_balance_update(account, params)
      account.update_balance(
        balance: params[:amount],
        date: params[:date],
        currency: params[:currency],
        notes: params[:notes],
        existing_valuation_id: params[:existing_valuation_id]
      )
    end
end
