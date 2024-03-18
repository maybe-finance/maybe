class TransactionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_transaction, only: %i[ show edit update destroy ]

  def index
    search_params = params[:q] || {}
    period = Period.find_by_name(search_params[:date])
    if period&.date_range
      search_params.merge!({ date_gteq: period.date_range.begin, date_lteq: period.date_range.end })
    end

    @q = Current.family.transactions.ransack(search_params)
    @pagy, @transactions = pagy(@q.result.order(date: :desc), items: 50)

    respond_to do |format|
      format.html # For full page reloads
      format.turbo_stream # For Turbo Frame requests
    end
  end

  def show
  end

  def new
    @transaction = Transaction.new
  end

  def edit
  end

  def create
    account = Current.family.accounts.find(params[:transaction][:account_id])

    @transaction = account.transactions.build(transaction_params)

    respond_to do |format|
      if @transaction.save
        format.html { redirect_to transactions_url, notice: t(".success") }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @transaction.update(transaction_params)
        format.html { redirect_to transaction_url(@transaction), notice: t(".success") }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.append("notification-tray", partial: "shared/notification", locals: { type: "success", content: t(".success") }),
            turbo_stream.replace("transaction_#{@transaction.id}", partial: "transactions/transaction", locals: { transaction: @transaction })
          ]
        end
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @transaction.destroy!

    respond_to do |format|
      format.html { redirect_to transactions_url, notice: t(".success") }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_transaction
      @transaction = Transaction.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def transaction_params
      params.require(:transaction).permit(:name, :date, :amount, :currency, :notes, :excluded, :category_id)
    end
end
