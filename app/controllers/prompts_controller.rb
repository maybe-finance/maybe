class PromptsController < ApplicationController
  before_action :authenticate_user!
  
  def index
    if params[:category].present?
      # Categories is an array column in the prompts table
      @prompts = Prompt.where("categories @> ARRAY[?]::varchar[]", params[:category])
    else
      @prompts = Prompt.all
    end
  end
end
