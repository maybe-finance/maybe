class Import::RowsController < ApplicationController
  before_action :set_import
  before_action :set_row_data, only: %i[update]

  def update
    @row.assign_attributes(row_params)
    @row.save(validate: false)

    respond_to do |format|
      format.html { redirect_to clean_import_path(@import) }
      format.turbo_stream { render "imports/rows/update" }
    end
  end

  private

    def set_import
      @import = Current.family.imports.find(params[:import_id])
    end

    def set_row_data
      @row = @import.rows.find(params[:id])
      @field = row_params.keys.first
    end

    def row_params
      params.require(:import_row).permit(:name, :date, :amount, :category, :tags)
    end
end
