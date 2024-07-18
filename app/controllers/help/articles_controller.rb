class Help::ArticlesController < ApplicationController
  layout "with_sidebar"

  def show
    @article = Help::Article.find(params[:id])

    unless @article
      head :not_found
    end
  end
end
