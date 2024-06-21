class Family::TransactionsController < ApplicationController
  layout "with_sidebar"

  def index
    @q = search_params
    result = Current.family.transactions.search(@q).ordered
    @pagy, @transactions = pagy(result, items: params[:per_page] || "10")

    @totals = {
      count: result.select { |t| t.currency == Current.family.currency }.count,
      income: result.income_total(Current.family.currency).abs,
      expense: result.expense_total(Current.family.currency)
    }
  end

  private

    def search_params
      params.fetch(:q, {}).permit(:start_date, :end_date, :search, accounts: [], account_ids: [], categories: [], merchants: [])
    end
end
