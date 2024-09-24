class Import::ConfirmsController < ApplicationController
  layout "imports"

  before_action :set_import

  def show
    redirect_to import_clean_path(@import), alert: "You have invalid data, please edit until all errors are resolved" unless @import.cleaned?
  end

  def update
  end

  private
    def set_import
      @import = Current.family.imports.find(params[:import_id])
    end
end
