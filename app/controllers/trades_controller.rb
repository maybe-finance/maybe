class TradesController < ApplicationController
  include EntryableResource

  def create
    @entry = build_entry

    if @entry.save
      @entry.sync_account_later

      flash[:notice] = t("entries.create.success")

      respond_to do |format|
        format.html { redirect_back_or_to account_path(@entry.account) }

        redirect_target_url = request.referer || account_path(@entry.account)
        format.turbo_stream { render turbo_stream: turbo_stream.action(:redirect, redirect_target_url) }
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
              partial: "#{entryable_type.name.underscore.pluralize}/header",
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
    def build_entry
      TradeBuilder.new(create_entry_params)
    end

    def entry_params
      params.require(:entry).permit(
        :account_id, :name, :enriched_name, :date, :amount, :currency, :excluded, :notes, :nature,
        entryable_attributes: [ :id, :qty, :price ]
      )
    end

    def create_entry_params
      params.require(:entry).permit(
        :account_id, :date, :amount, :currency, :qty, :price, :ticker, :manual_ticker, :type, :transfer_account_id
      ).tap do |params|
        account_id = params.delete(:account_id)
        params[:account] = Current.family.accounts.find(account_id)
      end
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
