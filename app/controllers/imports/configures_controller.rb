class Imports::ConfiguresController < ApplicationController
  layout "imports"
  before_action :set_import

  def show
  end

  def update
  end

  private

    def set_import
      @import = Current.family.imports.find(params[:import_id])
    end
end
