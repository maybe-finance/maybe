class TransactionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_transaction, only: %i[ show edit update destroy ]

  def index
    search_params = session[ransack_session_key] || params[:q]
    @q = Current.family.transactions.ransack(search_params)
    result = @q.result.order(date: :desc)
    @pagy, @transactions = pagy(result, items: 10)
    @totals = {
      count: result.count,
      income: result.inflows.sum(&:amount_money).abs,
      expense: result.outflows.sum(&:amount_money).abs
    }
    @filter_list = Transaction.build_filter_list(search_params, Current.family)

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def search
    if params[:clear]
      session.delete(ransack_session_key)
    elsif params[:remove_param]
      current_params = session[ransack_session_key] || {}
      updated_params = delete_search_param(current_params, params[:remove_param], value: params[:remove_param_value])
      session[ransack_session_key] = updated_params
    elsif params[:q]
      session[ransack_session_key] = params[:q]
    end

    index

    respond_to do |format|
      format.html { render :index }
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("transactions_summary", partial: "transactions/summary", locals: { totals: @totals }),
          turbo_stream.replace("transactions_search_form", partial: "transactions/search_form", locals: { q: @q }),
          turbo_stream.replace("transactions_filters", partial: "transactions/filters", locals: { filters: @filter_list }),
          turbo_stream.replace("transactions_list", partial: "transactions/list", locals: { transactions: @transactions, pagy: @pagy })
        ]
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
    def delete_search_param(params, key, value: nil)
      if value
        params[key]&.delete(value)
        params.delete(key) if params[key].empty? # Remove key if it's empty after deleting value
      else
        params.delete(key)
      end

      params
    end

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
