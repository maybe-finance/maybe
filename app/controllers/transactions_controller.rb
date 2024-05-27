class TransactionsController < ApplicationController
  layout "with_sidebar"

  before_action :set_transaction, only: %i[ show edit update destroy ]

  def index
    @q = search_params
    result = Current.family.transactions.search(@q).ordered
    @pagy, @transactions = pagy(result, items: 10)

    @totals = {
      count: result.count,
      income: result.inflows.sum(&:amount_money).abs,
      expense: result.outflows.sum(&:amount_money).abs
    }
  end

  def show
  end

  def new
    @transaction = Transaction.new.tap do |txn|
      if params[:account_id]
        txn.account = Current.family.accounts.find(params[:account_id])
      end
    end
  end

  def edit
  end

  def create
    @transaction = Current.family.accounts
                     .find(params[:transaction][:account_id])
                     .transactions.build(transaction_params.merge(amount: amount))

    respond_to do |format|
      if @transaction.save
        @transaction.account.sync_later(@transaction.date)
        format.html { redirect_to transactions_url, notice: t(".success") }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      sync_start_date = if transaction_params[:date]
                          [ @transaction.date, Date.parse(transaction_params[:date]) ].compact.min
      else
        @transaction.date
      end

      if params[:transaction][:tag_id].present?
        tag = Current.family.tags.find(params[:transaction][:tag_id])
        @transaction.tags << tag unless @transaction.tags.include?(tag)
      end

      if params[:transaction][:remove_tag_id].present?
        @transaction.tags.delete(params[:transaction][:remove_tag_id])
      end

      if @transaction.update(transaction_params)
        @transaction.account.sync_later(sync_start_date)

        format.html { redirect_to transaction_url(@transaction), notice: t(".success") }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.append("notification-tray", partial: "shared/notification", locals: { type: "success", content: { body: t(".success") } }),
            turbo_stream.replace("transaction_#{@transaction.id}", partial: "transactions/transaction", locals: { transaction: @transaction })
          ]
        end
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @account = @transaction.account
    sync_start_date = @account.transactions.where("date < ?", @transaction.date).order(date: :desc).first&.date
    @transaction.destroy!
    @account.sync_later(sync_start_date)

    respond_to do |format|
      format.html { redirect_to transactions_url, notice: t(".success") }
    end
  end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_transaction
      @transaction = Transaction.find(params[:id])
    end

    def amount
      if nature.income?
        transaction_params[:amount].to_d * -1
      else
        transaction_params[:amount].to_d
      end
    end

    def nature
      params[:transaction][:nature].to_s.inquiry
    end

    def search_params
      params.fetch(:q, {}).permit(:start_date, :end_date, :search, accounts: [], categories: [], merchants: [])
    end

    def transaction_params
      params.require(:transaction).permit(:name, :date, :amount, :currency, :notes, :excluded, :category_id, :merchant_id, :tag_id, :remove_tag_id).except(:tag_id, :remove_tag_id)
    end
end
