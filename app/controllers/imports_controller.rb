class ImportsController < ApplicationController

before_action :set_import, only: %i[ show edit update destroy ]

  def index
    @imports = Import.all
  end

  def show
  end

  def new
    @import = Import.new
  end

  def edit
  end

  def create
    account = Current.family.accounts.find(params[:import][:account_id])
    @import = Import.create!(account: account)

    redirect_to @import, notice: "Import was successfully created."
  end

  def update
    # TODO: handle mappings safely
    @import = Current.family.imports.find(params[:id])
    redirect_to @import, notice: "Import was successfully updated.", status: :see_other
  end

  def destroy
    @import.destroy!
    redirect_to imports_url, notice: "Import was successfully destroyed.", status: :see_other
  end

  private

  def set_import
    @import = Import.find(params[:id])
  end
end
