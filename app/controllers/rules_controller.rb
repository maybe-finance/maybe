class RulesController < ApplicationController
  before_action :set_rule, only: [ :show, :edit, :update, :destroy ]

  def index
    @rules = Current.family.rules
    render layout: "settings"
  end

  def show
  end

  def new
    @rule = Current.family.rules.build(
      resource_type: params[:resource_type] || "transaction",
      conditions: [
        Rule::Condition.new(condition_type: "transaction_name", operator: "like", value: "test")
      ],
      actions: [
        Rule::Action.new(action_type: "set_transaction_category", value: Current.family.categories.first.id)
      ]
    )

    @template_condition = Rule::Condition.new(rule: @rule, condition_type: "transaction_name")
    @template_action = Rule::Action.new(rule: @rule, action_type: "set_transaction_category")
  end

  def create
    puts rule_params.inspect
    Current.family.rules.create!(rule_params)
    redirect_to rules_path
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
