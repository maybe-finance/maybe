class TagsController < ApplicationController
  layout :with_sidebar

  before_action :set_tag, only: %i[ edit update ]

  def index
    @tags = Current.family.tags.alphabetically
  end

  def new
    @tag = Current.family.tags.new color: Tag::COLORS.sample
  end

  def create
    Current.family.tags.create!(tag_params)
    redirect_to tags_path, notice: t(".created")
  end

  def edit
  end

  def update
    @tag.update!(tag_params)
    redirect_to tags_path, notice: t(".updated")
  end

  private

    def set_tag
      @tag = Current.family.tags.find(params[:id])
    end

    def tag_params
      params.require(:tag).permit(:name, :color)
    end
end
