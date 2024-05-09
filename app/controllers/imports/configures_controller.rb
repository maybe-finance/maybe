class Imports::ConfiguresController < ApplicationController
  layout "imports"
  before_action :set_import

  def show
  end

  def update
    if @import.update(import_params)
      redirect_to import_clean_path(@import), notice: "Mappings saved"
    else
      flash.now[:error] = @import.errors.full_messages.first
      render :show, status: :unprocessable_entity
    end
  end

  private

    def set_import
      @import = Current.family.imports.find(params[:import_id])
    end

    def import_params
      params.require(:import).permit(column_mappings: [ :date, :merchant, :category, :amount ])
    end
end
