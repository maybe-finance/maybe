class Transactions::SearchesController < ApplicationController
  include Searchable

  def update
    update_search_params(search_params)
  end

  def destroy
    clear_search
  end

  private

    def search_params
      params.require(:q)
    end
end
