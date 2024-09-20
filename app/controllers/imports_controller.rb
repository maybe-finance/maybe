require "ostruct"

class ImportsController < ApplicationController
  before_action :set_import, except: %i[index new create]

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
    @import.update! account: account, col_sep: params[:import][:col_sep]

    redirect_to load_import_path(@import), notice: t(".import_updated")
  end

  def create
    account = Current.family.accounts.find(params[:import][:account_id])
    @import = Import.create! account: account, col_sep: params[:import][:col_sep]

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
    @import.update! import_params
    redirect_to clean_import_path(@import), notice: t(".column_mappings_saved")
  end

  def clean
    unless @import.loaded?
      redirect_to load_import_path(@import), alert: t(".invalid_csv")
    end
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

    def import_params
      params.require(:import).permit(:raw_file_str, column_mappings: Import::FIELDS, csv_update: [ :row_idx, :col_idx, :value ])
    end
end
