class SecuritiesController < ApplicationController
  def import
    SecuritiesImportJob.perform_later(params[:exchange_mic])
  end
end
