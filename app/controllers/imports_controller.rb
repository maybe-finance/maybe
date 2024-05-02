class ImportsController < ApplicationController
  before_action :set_import, only: %i[ show edit update destroy ]

  # GET /imports
  def index
    @imports = Import.all
  end

  # GET /imports/1
  def show
  end

  # GET /imports/new
  def new
    @import = Import.new
  end

  # GET /imports/1/edit
  def edit
  end

  # POST /imports
  def create
    @import = Import.new(import_params)

    if @import.save
      redirect_to @import, notice: "Import was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /imports/1
  def update
    if @import.update(import_params)
      redirect_to @import, notice: "Import was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /imports/1
  def destroy
    @import.destroy!
    redirect_to imports_url, notice: "Import was successfully destroyed.", status: :see_other
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_import
    @import = Import.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def import_params
    params.require(:import).permit(:account_id, :column_mappings)
  end
end
