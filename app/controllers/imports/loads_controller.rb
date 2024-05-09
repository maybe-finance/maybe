class Imports::LoadsController < ApplicationController
  layout "imports"
  before_action :set_import

  def show
  end

  def update
    puts "The test is running correctly"
    if @import.update(import_params)
      redirect_to import_configure_path(@import), notice: "Import uploaded"
    else
      flash.now[:error] = @import.errors.full_messages.to_sentence
      render :show, status: :unprocessable_entity
    end
  end

  private

    def set_import
      @import = Current.family.imports.find(params[:import_id])
    end

    def import_params
      params.require(:import).permit(:raw_csv)
    end
end
