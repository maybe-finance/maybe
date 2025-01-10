class CategoriesController < ApplicationController
  layout :with_sidebar

  before_action :set_category, only: %i[show edit update destroy]
  before_action :set_transaction, only: :create

  def index
    @categories = Current.family.categories.alphabetically
  end

  def new
    @category = Current.family.categories.new color: Category::COLORS.sample
    @categories = Current.family.categories.alphabetically.where(parent_id: nil).where.not(id: @category.id)
  end

  def show
  end

  def create
    @category = Current.family.categories.new(category_params)

    if @category.save
      @transaction.update(category_id: @category.id) if @transaction

      flash[:notice] = t(".success")

      redirect_target_url = request.referer || categories_path
      respond_to do |format|
        format.html { redirect_back_or_to categories_path, notice: t(".success") }
        format.turbo_stream { render turbo_stream: turbo_stream.action(:redirect, redirect_target_url) }
      end
    else
      @categories = Current.family.categories.alphabetically.where(parent_id: nil).where.not(id: @category.id)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @categories = Current.family.categories.alphabetically.where(parent_id: nil).where.not(id: @category.id)
  end

  def update
    @category.update! category_params

    redirect_back_or_to categories_path, notice: t(".success")
  end

  def destroy
    @category.destroy

    redirect_back_or_to categories_path, notice: t(".success")
  end

  def bootstrap
    Current.family.categories.bootstrap_defaults

    redirect_back_or_to categories_path, notice: t(".success")
  end

  private
    def set_category
      @category = Current.family.categories.find(params[:id])
    end

    def set_transaction
      if params[:transaction_id].present?
        @transaction = Current.family.transactions.find(params[:transaction_id])
      end
    end

    def category_params
      params.require(:category).permit(:name, :color, :parent_id, :classification, :lucide_icon)
    end
end
