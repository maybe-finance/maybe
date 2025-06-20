class TradesController < ApplicationController
  include EntryableResource

  # Defaults to a buy trade
  def new
    @account = Current.family.accounts.find_by(id: params[:account_id])
    @model = Current.family.entries.new(
      account: @account,
      currency: @account ? @account.currency : Current.family.currency,
      entryable: Trade.new
    )
  end

  # Can create a trade, transaction (e.g. "fees"), or transfer (e.g. "withdrawal")
  def create
    @account = Current.family.accounts.find(params[:account_id])
    @model = Trade::CreateForm.new(create_params.merge(account: @account)).create

    if @model.persisted?
      flash[:notice] = t("entries.create.success")

      respond_to do |format|
        format.html { redirect_back_or_to account_path(@account) }
        format.turbo_stream { stream_redirect_back_or_to account_path(@account) }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @entry.update(update_entry_params)
      @entry.sync_account_later

      respond_to do |format|
        format.html { redirect_back_or_to account_path(@entry.account), notice: t("entries.update.success") }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(
              "header_entry_#{@entry.id}",
              partial: "trades/header",
              locals: { entry: @entry }
            ),
            turbo_stream.replace("entry_#{@entry.id}", partial: "entries/entry", locals: { entry: @entry })
          ]
        end
      end
    else
      render :show, status: :unprocessable_entity
    end
  end

  private
    def entry_params
      params.require(:entry).permit(
        :name, :date, :amount, :currency, :excluded, :notes, :nature,
        entryable_attributes: [ :id, :qty, :price ]
      )
    end

    def create_params
      params.require(:model).permit(
        :date, :amount, :currency, :qty, :price, :ticker, :manual_ticker, :type, :transfer_account_id
      )
    end

    def update_entry_params
      return entry_params unless entry_params[:entryable_attributes].present?

      update_params = entry_params
      update_params = update_params.merge(entryable_type: "Trade")

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
