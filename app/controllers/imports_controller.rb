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
    @import.update!(account_id: params[:import][:account_id])

    redirect_to load_import_path(@import), notice: "Import updated"
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
      redirect_to import_configure_path(@import), notice: "Import uploaded"
    else
      flash.now[:error] = @import.errors.full_messages.to_sentence
      render :load, status: :unprocessable_entity
    end
  end

  private

    def set_import
      @import = Current.family.imports.find(params[:id])
    end

    def import_params
      params.require(:import).permit(:raw_csv)
    end
end
