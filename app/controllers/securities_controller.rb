class SecuritiesController < ApplicationController
  def index
    query = params[:q]
    return render json: [] if query.blank? || query.length < 2 || query.length > 100

    @securities = Security.search_provider({
      search: query,
      country: params[:country_code] == "US" ? "US" : nil
    })
  end
end
