class TransactionsController < ApplicationController
  layout :with_sidebar

  def index
    @q = search_params
    search_query = Current.family.transactions.search(@q).includes(:entryable).reverse_chronological
    @pagy, @transaction_entries = pagy(search_query, limit: params[:per_page] || "50")

    totals_query = search_query.incomes_and_expenses
    family_currency = Current.family.currency

    @totals = {
      count: totals_query.select { |t| t.currency == family_currency }.count,
      income: totals_query.income_total(family_currency).abs,
      expense: totals_query.expense_total(family_currency)
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
