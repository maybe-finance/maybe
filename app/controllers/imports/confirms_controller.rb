class Imports::ConfirmsController < ApplicationController
  layout "imports"
  before_action :set_import

  def show
    unless @import.row_errors.flatten.empty?
      flash[:error] = "There are invalid values"
      redirect_to import_clean_path(@import)
    end
  end

  def update
    @import.confirm!
    redirect_to transactions_path, notice: "Import complete!"
  end

  private

    def set_import
      @import = Current.family.imports.find(params[:import_id])
    end
end
