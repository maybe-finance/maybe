class Imports::LoadsController < ApplicationController
  layout "imports"
  before_action :set_import

  def show
  end

  def update
    redirect_to import_configure_path(@import)
  end

  private

    def set_import
      @import = Current.family.imports.find(params[:import_id])
    end
end
