class ImportsController < ApplicationController
  def index 
    @imports = Current.family.imports
    
    render layout: with_sidebar
  end 
end
