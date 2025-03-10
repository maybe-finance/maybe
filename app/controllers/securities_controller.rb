class SecuritiesController < ApplicationController
  def index
    @securities = Security.search_provider({
      search: params[:q],
      country: params[:country_code] == "US" ? "US" : nil
    })
  end
end
