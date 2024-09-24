class Import::ConfigurationsController < ApplicationController
  layout "imports"

  before_action :set_import

  def show
  end

  def update
    @import.update!(import_params)
    @import.generate_rows_from_csv
    redirect_back_or_to import_configuration_path(@import)
  end

  private
    def set_import
      @import = Current.family.imports.find(params[:import_id])
    end

    def import_params
      params.require(:import).permit(:date_col_label, :date_format, :name_col_label, :category_col_label, :tags_col_label, :amount_col_label, :amount_sign_format, :account_col_label)
    end
end
