class TransactionsController < ApplicationController
  layout :with_sidebar

  def index
    @q = search_params
    result = Current.family.entries.account_transactions.search(@q).reverse_chronological
    @pagy, @transaction_entries = pagy(result, limit: params[:per_page] || "50")

    @totals = {
      count: result.select { |t| t.currency == Current.family.currency }.count,
      income: result.income_total(Current.family.currency).abs,
      expense: result.expense_total(Current.family.currency)
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
