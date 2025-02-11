class Tag::DeletionsController < ApplicationController
  before_action :set_tag
  before_action :set_replacement_tag, only: :create

  def new
  end

  def create
    @tag.replace_and_destroy! @replacement_tag
    redirect_back_or_to tags_path, notice: t(".deleted")
  end

  private

    def set_tag
      @tag = Current.family.tags.find_by(id: params[:tag_id])
    end

    def set_replacement_tag
      @replacement_tag = Current.family.tags.find_by(id: params[:replacement_tag_id])
    end
end
