class Transactions::CategoriesController < ApplicationController
  before_action :set_category, only: %i[ edit update destroy ]

  def index
    @categories = Current.family.transaction_categories.alphabetically
  end

  def create
    Current.family.transaction_categories.create! category_params

    redirect_back_or_to transactions_path, notice: t(".success")
  end

  def edit
  end

  def update
    @category.update! category_params

    redirect_back_or_to transactions_path, notice: t(".success")
  end

  def destroy
    @category.destroy!

    redirect_back_or_to transactions_path, notice: t(".success")
  end

  private
    def set_category
      @category = Current.family.transaction_categories.find(params[:id])
    end

    def category_params
      params.require(:transaction_category).permit(:name, :color)
    end
end
