class ValuationsController < ApplicationController
  include EntryableResource, StreamExtensions

  def create
    account = Current.family.accounts.find(params.dig(:entry, :account_id))

    result = account.update_balance(
      balance: entry_params[:amount],
      date: entry_params[:date],
      currency: entry_params[:currency],
      notes: entry_params[:notes]
    )

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
    result = @entry.account.update_balance(
      date: @entry.date,
      balance: entry_params[:amount],
      currency: entry_params[:currency],
      notes: entry_params[:notes]
    )

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
end
