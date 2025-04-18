class SecuritiesController < ApplicationController
  def index
    @securities = Security.search_provider(
      params[:q],
      country_code: params[:country_code] == "US" ? "US" : nil
    )
  end
end
