class Import::UploadsController < ApplicationController
  layout "imports"

  before_action :set_import

  def show
  end

  def update
    if csv_valid?(csv_str)
      @import.assign_attributes(raw_file_str: csv_str, col_sep: upload_params[:col_sep])
      @import.save!(validate: false)

      redirect_back_or_to import_upload_path(@import), notice: "Import updated"
    else
      flash.now[:alert] = "Must be valid CSV with headers and at least one row of data"

      render :show, status: :unprocessable_entity
    end
  end

  private
    def set_import
      @import = Current.family.imports.find(params[:import_id])
    end

    def csv_str
      @csv_str ||= upload_params[:csv_file]&.read || upload_params[:raw_file_str]
    end

    def csv_valid?(str)
      require "csv"

      begin
        csv = CSV.parse(str || "", headers: true)
        return false if csv.headers.empty?
        return false if csv.count == 0
        true
      rescue CSV::MalformedCSVError
        false
      end
    end

    def upload_params
      params.require(:import).permit(:raw_file_str, :csv_file, :col_sep)
    end
end
