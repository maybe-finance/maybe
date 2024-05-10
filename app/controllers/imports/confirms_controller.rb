class Imports::ConfirmsController < ApplicationController
  layout "imports"
  before_action :set_import

  def show
  end

  def update
    @import.confirm!
    redirect_to transactions_path, notice: "Import complete!"
  end

  private

    def set_import
      @import = Current.family.imports.find(params[:import_id])
    end
end
