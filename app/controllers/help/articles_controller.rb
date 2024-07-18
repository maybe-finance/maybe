class Help::ArticlesController < ApplicationController
  layout "with_sidebar"

  before_action :set_article

  def show
    @article = Help::Article.find(params[:id])

    unless @article
      head :not_found
    end
  end

  private

    def set_article
      @article = Help::Article.find(params[:id])
    end
end
