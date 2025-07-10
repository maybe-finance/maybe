module AccountableResource
  extend ActiveSupport::Concern

  included do
    include ScrollFocusable, Periodable, StreamExtensions

    before_action :set_account, only: [ :show, :edit, :update, :destroy ]
    before_action :set_link_options, only: :new
  end

  class_methods do
    def permitted_accountable_attributes(*attrs)
      @permitted_accountable_attributes = attrs if attrs.any?
      @permitted_accountable_attributes ||= [ :id ]
    end
  end

  def new
    @account = Current.family.accounts.build(
      currency: Current.family.currency,
      accountable: accountable_type.new
    )
  end

  def show
    @chart_view = params[:chart_view] || "balance"
    @q = params.fetch(:q, {}).permit(:search)
    entries = @account.entries.search(@q).reverse_chronological

    set_focused_record(entries, params[:focused_record_id])

    @pagy, @entries = pagy(entries, limit: params[:per_page] || "10", params: ->(params) { params.except(:focused_record_id) })
  end

  def edit
  end

  def create
    @account = Current.family.accounts.create_and_sync(account_params.except(:return_to))
    @account.lock_saved_attributes!

    respond_to do |format|
      format.html { redirect_to account_params[:return_to].presence || account_path(@account), notice: accountable_type.name.underscore.humanize + " account created" }
      format.turbo_stream { stream_redirect_to account_params[:return_to].presence || account_path(@account), notice: accountable_type.name.underscore.humanize + " account created" }
    end
  end

  def update
    form = Account::OverviewForm.new(
      account: @account,
      name: account_params[:name],
      currency: account_params[:currency],
      current_balance: account_params[:balance],
      current_cash_balance: @account.depository? ? account_params[:balance] : "0"
    )

    result = form.save

    if result.success?
      respond_to do |format|
        format.html { redirect_back_or_to account_path(@account), notice: accountable_type.name.underscore.humanize + " account updated" }
        format.turbo_stream { stream_redirect_to account_path(@account), notice: accountable_type.name.underscore.humanize + " account updated" }
      end
    else
      @error_message = result.error || "Unable to update account details."
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @account.linked?
      redirect_to account_path(@account), alert: "Cannot delete a linked account"
    else
      @account.destroy_later
      redirect_to accounts_path, notice: t("accounts.destroy.success", type: accountable_type.name.underscore.humanize)
    end
  end

  private
    def set_link_options
      @show_us_link = Current.family.can_connect_plaid_us?
      @show_eu_link = Current.family.can_connect_plaid_eu?
    end

    def accountable_type
      controller_name.classify.constantize
    end

    def set_account
      @account = Current.family.accounts.find(params[:id])
    end

    def account_params
      params.require(:account).permit(
        :name, :balance, :subtype, :currency, :accountable_type, :return_to, :tracking_start_date,
        accountable_attributes: self.class.permitted_accountable_attributes
      )
    end
end
