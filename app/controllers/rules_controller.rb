class RulesController < ApplicationController
  before_action :set_rule, only: [ :show, :edit, :update, :destroy ]

  def index
    @rules = Current.family.rules
    render layout: "settings"
  end

  def show
  end

  def new
    @rule = Current.family.rules.new(resource_type: params[:resource_type] || "transaction")
  end

  def create
    Current.family.rules.create!(rule_params)
    redirect_to rules_path
  rescue => e
    puts e.inspect
    puts e.backtrace
  end

  def edit
    @rule = Current.family.rules.find(params[:id])
  end

  def update
    @rule.update!(rule_params)
    redirect_to rules_path
  end

  def destroy
    @rule.destroy
    redirect_to rules_path
  end

  private

    def set_rule
      @rule = Current.family.rules.find(params[:id])
    end

    def rule_params
      params.require(:rule).permit(
        :resource_type, :effective_date, :active,
        conditions_attributes: [
          :id, :condition_type, :operator, :value,
          sub_conditions_attributes: [ :id, :condition_type, :operator, :value ]
        ],
        actions_attributes: [
          :id, :action_type, :value
        ]
      )
    end
end
