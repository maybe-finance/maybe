class TransactionsController < ApplicationController
  layout :with_sidebar

  def index
    @q = search_params
    search_query = Current.family.transactions.search(@q).includes(:entryable).reverse_chronological
    @pagy, @transaction_entries = pagy(search_query, limit: params[:per_page] || "50")

    @totals = {
      count: search_query.select { |t| t.currency == Current.family.currency }.count,
      income: search_query.income_total(Current.family.currency).abs,
      expense: search_query.expense_total(Current.family.currency)
    }
  end

  private
    def search_params
      params.fetch(:q, {})
            .permit(
              :start_date, :end_date, :search, :amount,
              :amount_operator, accounts: [], account_ids: [],
              categories: [], merchants: [], types: [], tags: []
            )
    end
end
