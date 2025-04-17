class ValuationsController < ApplicationController
  include EntryableResource

  def create
    account = Current.family.accounts.find(params.dig(:entry, :account_id))
    @entry = account.entries.new(entry_params.merge(entryable: Valuation.new))

    if @entry.save
      @entry.sync_account_later

      flash[:notice] = "Balance created"

      respond_to do |format|
        format.html { redirect_back_or_to account_path(@entry.account) }
        format.turbo_stream { stream_redirect_back_or_to(account_path(@entry.account)) }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @entry.update(entry_params)
      @entry.sync_account_later

      respond_to do |format|
        format.html { redirect_back_or_to account_path(@entry.account), notice: "Balance updated" }
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
      render :show, status: :unprocessable_entity
    end
  end

  private
    def entry_params
      params.require(:entry)
            .permit(:name, :date, :amount, :currency, :notes)
    end
end
