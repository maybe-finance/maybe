class ImportsController < ApplicationController
  before_action :set_import, only: %i[show publish destroy revert]

  def publish
    @import.publish_later

    redirect_to import_path(@import), notice: "Your import has started in the background."
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
    if !@import.uploaded?
      redirect_to import_upload_path(@import), alert: "Please finalize your file upload."
    elsif !@import.publishable?
      redirect_to import_confirm_path(@import), alert: "Please finalize your mappings before proceeding."
    end
  end

  def revert
    @import.revert_later
    redirect_to imports_path, notice: "Import is reverting in the background."
  end

  def destroy
    @import.destroy

    redirect_to imports_path, notice: "Your import has been deleted."
  end

  private
    def set_import
      @import = Current.family.imports.find(params[:id])
    end

    def import_params
      params.require(:import).permit(:type)
    end
end
