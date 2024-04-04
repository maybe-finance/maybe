class Transactions::CategoriesController < ApplicationController
  before_action :set_category, only: [ :update, :destroy ]

  def create
    if Current.family.transaction_categories.create(category_params)
      redirect_to transactions_path, notice: t(".success")
    else
      render transactions_path, status: :unprocessable_entity, notice: t(".error")
    end
  end

  def update
    if @category.update(category_params)
      redirect_to transactions_path, notice: t(".success")
    else
      render transactions_path, status: :unprocessable_entity, notice: t(".error")
    end
  end

  def destroy
    @category.destroy!
    redirect_to transactions_path, notice: t(".success")
  end

  private

  def set_category
    @category = Current.family.transaction_categories.find(params[:id])
  end

  def category_params
    params.require(:transaction_category).permit(:name, :name, :color) 
  end
end
