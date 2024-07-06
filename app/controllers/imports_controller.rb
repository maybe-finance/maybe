require "ostruct"

class ImportsController < ApplicationController
  before_action :set_import, except: %i[ index new create ]
  protect_from_forgery with: :null_session, include: %i[ upload_csv ]

  def index
    @imports = Current.family.imports
    render layout: "with_sidebar"
  end

  def new
    account = Current.family.accounts.find_by(id: params[:account_id])
    @import = Import.new account: account
  end

  def edit
  end

  def update
    account = Current.family.accounts.find(params[:import][:account_id])

    @import.update! account: account
    redirect_to load_import_path(@import), notice: t(".import_updated")
  end

  def create
    account = Current.family.accounts.find(params[:import][:account_id])
    @import = Import.create!(account: account)

    redirect_to load_import_path(@import), notice: t(".import_created")
  end

  def destroy
    @import.destroy!
    redirect_to imports_url, notice: t(".import_destroyed"), status: :see_other
  end

  def load
  end

  def load_csv
    if @import.update(import_params)
      redirect_to configure_import_path(@import), notice: t(".import_loaded")
    else
      flash.now[:error] = @import.errors.full_messages.to_sentence
      render :load, status: :unprocessable_entity
    end
  end

  def upload_csv
    raw_csv = params[:file].read

    begin
      csv = Import::Csv.new(raw_csv)
      if csv.valid?
        render turbo_stream: turbo_stream.action(
          :update_input, "raw_csv_text_area", raw_csv
        )
      else
        render json: { message: "CSV contents is not valid" }, status: :unprocessable_entity
      end
    rescue CSV::MalformedCSVError => error
      file_extension = params[:file].path.split(".").last
      render json: { message: "Expected file format CSV, but recieved #{file_extension}", error: error }, status: :bad_request
    end
  end

  def configure
    unless @import.loaded?
      redirect_to load_import_path(@import), alert: t(".invalid_csv")
    end
  end

  def update_mappings
    @import.update! import_params(@import.expected_fields.map(&:key))
    redirect_to clean_import_path(@import), notice: t(".column_mappings_saved")
  end

  def clean
    unless @import.loaded?
      redirect_to load_import_path(@import), alert: t(".invalid_csv")
    end
  end

  def update_csv
    update_params = import_params[:csv_update]

    @import.update_csv! \
      row_idx: update_params[:row_idx],
      col_idx: update_params[:col_idx],
      value: update_params[:value]

    render :clean
  end

  def confirm
    unless @import.cleaned?
      redirect_to clean_import_path(@import), alert: t(".invalid_data")
    end
  end

  def publish
    if @import.valid?
      @import.publish_later
      redirect_to imports_path, notice: t(".import_published")
    else
      flash.now[:error] = t(".invalid_data")
      render :confirm, status: :unprocessable_entity
    end
  end

  private

    def set_import
      @import = Current.family.imports.find(params[:id])
    end

    def import_params(permitted_mappings = nil)
      params.require(:import).permit(:raw_csv_str, column_mappings: permitted_mappings, csv_update: [ :row_idx, :col_idx, :value ])
    end
end
