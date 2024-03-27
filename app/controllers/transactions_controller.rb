class TransactionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_transaction, only: %i[ show edit update destroy ]

  def index
    search_params = session[ransack_session_key] || params[:q]
    @q = Current.family.transactions.ransack(search_params)
    @pagy, @transactions = pagy(@q.result.order(date: :desc), items: 20)
    @totals = {
      count: Current.family.transactions.count,
      income: Current.family.transactions.inflows.sum(&:amount_money).abs,
      expense: Current.family.transactions.outflows.sum(&:amount_money).abs
    }

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def search
    session[ransack_session_key] = params[:q] if params[:q]

    index

    respond_to do |format|
      format.html { render :index }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "transactions_list",
          partial: "transactions/list",
          locals: { transactions: @transactions, pagy: @pagy }
        )
      end
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
    def ransack_session_key
      :ransack_transactions_q
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_transaction
      @transaction = Transaction.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def transaction_params
      params.require(:transaction).permit(:name, :date, :amount, :currency, :notes, :excluded, :category_id)
    end
end
