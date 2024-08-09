class Account::EntriesController < ApplicationController
  layout :with_sidebar

  before_action :set_account
  before_action :set_entry, only: %i[ edit update show destroy ]

  def create
    # TODO: refactor after tests passing
    entry_params_modified = entry_params_with_defaults(entry_params)
    if entry_params_modified[:entryable_type] == "Account::Trade"
      ticker                   = entry_params_modified[:entryable_attributes].delete(:ticker)
      security                 = Security.find_or_create_by(ticker: ticker)
      price                    = entry_params_modified[:entryable_attributes][:price]
      qty                      = entry_params_modified[:entryable_attributes][:qty]
      qty                      = params[:account_entry][:type] == "buy" ? qty : -1 * qty.to_f
      amount                   = price.to_f * qty.to_f
      new_entryable_attributes = entry_params_modified[:entryable_attributes].merge(qty: qty, security_id: security.id)
      @entry                   = @account.entries.build(entry_params_modified.merge(amount: amount, entryable_attributes: new_entryable_attributes))
    else
      @entry = @account.entries.build(entry_params_modified)
    end

    if @entry.save
      @entry.sync_account_later
      redirect_to account_path(@account), notice: t(".success", name: @entry.entryable_name_short.upcase_first)
    else
      # TODO: this is not an ideal way to handle errors and should eventually be improved.
      # See: https://github.com/hotwired/turbo-rails/pull/367
      flash[:alert] = @entry.errors.full_messages.to_sentence
      redirect_to account_path(@account)
    end
  end

  def edit
    render entryable_view_path(:edit)
  end

  def update
    @entry.update!(entry_params)
    @entry.sync_account_later

    respond_to do |format|
      format.html { redirect_to account_entry_path(@account, @entry), notice: t(".success") }
      format.turbo_stream { render turbo_stream: turbo_stream.replace(@entry) }
    end
  end

  def show
    render entryable_view_path(:show)
  end

  def destroy
    @entry.destroy!
    @entry.sync_account_later
    redirect_back_or_to account_url(@entry.account), notice: t(".success")
  end

  private

    def entryable_view_path(action)
      @entry.entryable_type.underscore.pluralize + "/" + action.to_s
    end

    def set_account
      @account = Current.family.accounts.find(params[:account_id])
    end

    def set_entry
      @entry = @account.entries.find(params[:id])
    end

    def permitted_entryable_attributes
      entryable_type = @entry ? @entry.entryable_class.to_s : params[:account_entry][:entryable_type]

      case entryable_type
      when "Account::Transaction"
        [ :id, :notes, :excluded, :category_id, :merchant_id, tag_ids: [] ]
      when "Account::Trade"
        [ :id, :ticker, :qty, :price, :currency ]
      else
        [ :id ]
      end
    end

    def entry_params
      params.require(:account_entry)
        .permit(:name, :date, :amount, :currency, :entryable_type, entryable_attributes: permitted_entryable_attributes)
    end

    def amount
      if nature.income?
        entry_params[:amount].to_d.abs * -1
      else
        entry_params[:amount].to_d.abs
      end
    end

    def nature
      params[:account_entry][:nature].to_s.inquiry
    end

    # entryable_type is required here because Rails expects both of these params in this exact order (potential upstream bug)
    def entry_params_with_defaults(params)
      params.with_defaults(entryable_type: params[:entryable_type], entryable_attributes: {})
    end
end
