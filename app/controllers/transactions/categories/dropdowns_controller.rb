class Transactions::Categories::DropdownsController < ApplicationController
  before_action :set_from_params

  def show
    @categories = categories_scope.to_a.excluding(@selected_category).prepend(@selected_category).compact
    @selected_category_id = params[:selected_category_id]
  end

  private
  def set_from_params
    if params[:selected_category_id]
      @selected_category = categories_scope.find(params[:selected_category_id])
    end

    if params[:transaction_id]
      @transaction = Current.family.transactions.find(params[:transaction_id])
    end
  end

  def categories_scope
    Current.family.transaction_categories.alphabetically
  end
end
