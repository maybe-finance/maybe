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

  def update_csv
    if @import.update(import_params)
      redirect_to configure_import_path(@import), notice: "Import uploaded"
    else
      flash.now[:error] = @import.errors.full_messages.to_sentence
      render :load, status: :unprocessable_entity
    end
  end

  def configure
  end

  def update_mappings
    if @import.update(import_params)
      @import.rows.insert_all(@import.rows_mapped)
      redirect_to clean_import_path(@import), notice: "Mappings saved"
    else
      flash.now[:error] = @import.errors.full_messages.first
      render :configure, status: :unprocessable_entity
    end
  end

  def clean
  end

  def confirm
  end

  def publish
    redirect_to transactions_path, notice: "Import complete!"
  end

  private

    def set_import
      @import = Current.family.imports.find(params[:id])
    end

    def import_params
      params.require(:import).permit(:raw_csv, column_mappings: [ :date, :name, :category, :amount ])
    end
end
