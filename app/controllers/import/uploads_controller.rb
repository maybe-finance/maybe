class Import::UploadsController < ApplicationController
  layout "imports"

  before_action :set_import

  def show
  end

  def update
    if csv_valid?(csv_str)
      @import.account = Current.family.accounts.find_by(id: params.dig(:import, :account_id))
      @import.assign_attributes(raw_file_str: csv_str, col_sep: upload_params[:col_sep])
      @import.save!(validate: false)

      redirect_to import_configuration_path(@import, template_hint: true), notice: "CSV uploaded successfully."
    else
      flash.now[:alert] = "Must be valid CSV with headers and at least one row of data"

      render :show, status: :unprocessable_entity
    end
  end

  def download_sample
    # Generate CSV stripped of whitespace, since we use heredoc strings
    template = @import.csv_template

    clean_headers = template.headers.map(&:strip)

    sample_csv = CSV.generate do |csv|
      csv << clean_headers
      template.each do |row|
        clean_values = row.to_h.values.map(&:to_s).map(&:strip)
        csv << clean_values
      end
    end

    send_data sample_csv,
              filename: "#{@import.type.underscore.gsub('_import', '')}_sample.csv",
              type: "text/csv",
              disposition: "attachment"
  end

  private
    def set_import
      @import = Current.family.imports.find(params[:import_id])
    end

    def csv_str
      @csv_str ||= upload_params[:csv_file]&.read || upload_params[:raw_file_str]
    end

    def csv_valid?(str)
      begin
        csv = Import.parse_csv_str(str, col_sep: upload_params[:col_sep])
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
