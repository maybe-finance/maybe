class ImportsController < ApplicationController
  before_action :set_import, only: %i[show update destroy publish]

  def publish
    redirect_to import_path(@import), notice: "Import published."
  end

  def index
    @imports = Current.family.imports

    render layout: with_sidebar
  end

  def new
    @pending_import = Current.family.imports.ordered.pending.first
  end

  def create
    import = Current.family.imports.create! import_params

    redirect_to import_upload_path(import)
  end

  def show
  end

  def update
    @import.update! import_params

    redirect_to import_path(@import)
  end

  def destroy
    if @import.complete?
      redirect_to imports_path, alert: "You cannot delete completed imports."
    else
      @import.destroy
      redirect_to imports_path, notice: "Import deleted."
    end
  end

  private
    def set_import
      @import = Current.family.imports.find(params[:id])
    end

    def import_params
      params.require(:import).permit(:type)
    end
end
