class RulesController < ApplicationController
  before_action :set_rule, only: [ :show, :edit, :update, :destroy ]

  def index
    @rules = Current.family.rules
    render layout: "settings"
  end

  def show
  end

  def new
  end

  def create
  end

  def edit
  end

  def update
  end

  def destroy
  end

  private

    def set_rule
      @rule = Current.family.rules.find(params[:id])
    end

    def rule_params
      params.require(:rule).permit(:effective_date, :active)
    end
end
