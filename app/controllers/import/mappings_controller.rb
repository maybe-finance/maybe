class Import::MappingsController < ApplicationController
  before_action :set_import

  def create
    @import.mappings.create! \
      type: mapping_params[:type],
      key: mapping_params[:key],
      create_when_empty: create_when_empty,
      mappable: mappable

    redirect_back_or_to import_confirm_path(@import)
  end

  def update
    mapping = @import.mappings.find(params[:id])

    mapping.update! \
      create_when_empty: create_when_empty,
      mappable: mappable

    redirect_back_or_to import_confirm_path(@import)
  end

  private
    def mapping_params
      params.require(:import_mapping).permit(:type, :key, :mappable_id, :mappable_type)
    end

    def set_import
      @import = Current.family.imports.find(params[:import_id])
    end

    def mappable
      mappable_class = mapping_params[:mappable_type].constantize

      @mappable ||= mappable_class.find_by(id: mapping_params[:mappable_id], family: Current.family)
    end

    def create_when_empty
      mapping_params[:mappable_id] == "internal_new"
    end
end
