require "ostruct"

class ImportsController < ApplicationController
  before_action :set_import, except: %i[index new create]

  def index
    @imports = Current.family.imports
    render layout: "with_sidebar"
  end

  def new
    raw_type = params[:raw_type] || "csv"
    account = Current.family.accounts.find_by(id: params[:account_id])
    @import = Import.new account: account, raw_type: raw_type
  end

  def edit
  end

  def update
    account = Current.family.accounts.find(params[:import][:account_id])
    pdf_regex = params[:import][:pdf_regex_id].present? ? Current.family.pdf_regexes.find(params[:import][:pdf_regex_id]) : nil
    @import.update! account: account, col_sep: params[:import][:col_sep], pdf_regex: pdf_regex

    redirect_to load_import_path(@import), notice: t(".import_updated")
  end

  def create
    create_params = params.require(:import).permit(:col_sep, :raw_type)
    account = Current.family.accounts.find(params[:import][:account_id])
    pdf_regex = params[:import][:pdf_regex_id].present? ? Current.family.pdf_regexes.find(params[:import][:pdf_regex_id]) : nil

    @import = Import.create! account: account, raw_type: create_params[:raw_type] || "csv", col_sep: create_params[:col_sep], pdf_regex: pdf_regex

    redirect_to load_import_path(@import), notice: t(".import_created")
  end

  def destroy
    @import.destroy!
    redirect_to imports_url, notice: t(".import_destroyed"), status: :see_other
  end

  def load
  end

  def upload_csv
    begin
      @import.raw_file_str = import_params[:raw_file_str].read
    rescue NoMethodError
      flash.now[:alert] = "Please select a file to upload"
      render :load, status: :unprocessable_entity and return
    end
    if @import.save
      redirect_to configure_import_path(@import), notice: t(".import_loaded")
    else
      flash.now[:alert] = @import.errors.full_messages.to_sentence
      render :load, status: :unprocessable_entity
    end
  end

  def load_csv
    if @import.update(import_params)
      redirect_to configure_import_path(@import), notice: t(".import_loaded")
    else
      flash.now[:alert] = @import.errors.full_messages.to_sentence
      render :load, status: :unprocessable_entity
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
      params.require(:import).permit(:raw_file_str, column_mappings: permitted_mappings, csv_update: [ :row_idx, :col_idx, :value ])
    end
end
