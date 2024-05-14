require "ostruct"

class ImportsController < ApplicationController
  before_action :set_import, except: %i[ index new create ]

  def index
    @imports = Current.family.imports
    render layout: "with_sidebar"
  end

  def new
    @import = Import.new
  end

  def edit
  end

  def update
    account = Current.family.accounts.find(params[:import][:account_id])

    if @import.update(account: account)
      redirect_to load_import_path(@import), notice: "Import updated"
    else
      flash.now[:error] = "Could not update account"
      render :edit, status: :unprocessable_entity
    end
  end

  def create
    account = Current.family.accounts.find(params[:import][:account_id])
    @import = Import.create!(account: account)

    redirect_to load_import_path(@import), notice: "Import was successfully created."
  end

  def destroy
    @import.destroy!
    redirect_to imports_url, notice: "Import was successfully destroyed.", status: :see_other
  end

  def load
  end

  def load_csv
    if @import.update(import_params)
      redirect_to configure_import_path(@import), notice: "Import uploaded"
    else
      flash.now[:error] = @import.errors.full_messages.to_sentence
      render :load, status: :unprocessable_entity
    end
  end

  def configure
    unless @import.loaded?
      redirect_to load_import_path(@import), alert: "Please load a valid CSV first"
    end
  end

  def update_mappings
    if @import.update(import_params)
      redirect_to clean_import_path(@import), notice: "Mappings saved"
    else
      flash.now[:error] = @import.errors.full_messages.first
      render :configure, status: :unprocessable_entity
    end
  end

  def clean
    unless @import.configured?
      redirect_to configure_import_path(@import), alert: "You have not configured your column mappings"
    end
  end

  def update_csv
    @import.update_csv! \
      row_idx: Integer(update_csv_params[:row_idx]),
      col_idx: Integer(update_csv_params[:col_idx]),
      value: update_csv_params[:value]

    render :clean
  end

  def confirm
    unless @import.cleaned?
      redirect_to clean_import_path(@import), alert: "You have invalid data, please fix before continuing"
    end
  end

  def publish
    if @import.valid?
      @import.publish_later
      redirect_to imports_path, notice: "Import has started in the background"
    else
      flash.now[:error] = "Import is not valid, please return to prior steps to fix this"
      render :confirm, status: :unprocessable_entity
    end
  end

  private

    def set_import
      @import = Current.family.imports.find(params[:id])
    end

    def import_params
      params.require(:import).permit(:raw_csv, column_mappings: [ :date, :name, :category, :amount ])
    end

    def update_csv_params
      params.require(:csv_update).permit(:row_idx, :col_idx, :value)
    end
end
