class Account::EntriesController < ApplicationController
  layout :with_sidebar

  before_action :set_account

  def index
    @q = search_params
    @pagy, @entries = pagy(entries_scope.search(@q).reverse_chronological, limit: params[:per_page] || "10")
  end

  private
    def set_account
      @account = Current.family.accounts.find(params[:account_id])
    end

    def entries_scope
      scope = Current.family.entries
      scope = scope.where(account: @account) if @account
      scope
    end

    def search_params
      params.fetch(:q, {})
            .permit(:search)
    end
end
