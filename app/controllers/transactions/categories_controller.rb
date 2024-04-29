class Transactions::CategoriesController < ApplicationController
  before_action :set_category, only: %i[ edit update destroy ]
  before_action :set_transaction, only: :create

  def index
    @categories = Current.family.transaction_categories.alphabetically
  end

  def new
    @category = Current.family.transaction_categories.new color: Transaction::Category::COLORS.sample
  end

  def create
    Transaction::Category.transaction do
      category = Current.family.transaction_categories.create!(category_params)
      @transaction.update!(category_id: category.id) if @transaction
    end

    redirect_back_or_to transactions_path, notice: t(".success")
  end

  def edit
  end

  def update
    @category.update! category_params

    redirect_back_or_to transactions_path, notice: t(".success")
  end

  private
    def set_category
      @category = Current.family.transaction_categories.find(params[:id])
    end

    def set_transaction
      if params[:transaction_id]
        @transaction = Current.family.transactions.find(params[:transaction_id])
      end
    end

    def category_params
      params.require(:transaction_category).permit(:name, :color)
    end
end
