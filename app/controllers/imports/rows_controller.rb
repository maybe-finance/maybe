class Imports::RowsController < ApplicationController
  def update
    row = Current.family
                 .imports.find(params[:import_id])
                 .rows.find(params[:id])

    row.update! row_params
    redirect_to clean_import_path(row.import)
  end

  private

    def row_params
      params.require(:import_row).permit(:name, :date, :category, :merchant, :amount)
    end
end
