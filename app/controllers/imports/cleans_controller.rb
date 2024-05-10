class Imports::CleansController < ApplicationController
  layout "imports"
  before_action :set_import

  def show
  end

  def update
    @import.update_cell! \
      row_idx: import_params[:row_idx],
      col_idx: import_params[:col_idx],
      value: import_params[:value]

    render :show
  end

  private

    def set_import
      @import = Current.family.imports.find(params[:import_id])
    end

    def import_params
      permitted_params = params.require(:csv_update).permit(:row_idx, :col_idx, :value)
      permitted_params[:row_idx] = permitted_params[:row_idx].to_i
      permitted_params[:col_idx] = permitted_params[:col_idx].to_i
      permitted_params
    end
end
