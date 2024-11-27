class SecuritiesController < ApplicationController
  def index
    query = params[:q]
    return render json: [] if query.blank? || query.length < 2 || query.length > 100

    @securities = Security.search({
      search: query,
      country: country_code_filter
    })
  end

  private
    def country_code_filter
      filter = params[:country_code]
      filter = "#{filter},US" unless filter == "US"
      filter
    end
end
