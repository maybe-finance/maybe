class RulesController < ApplicationController
  include StreamExtensions

  before_action :set_rule, only: [  :edit, :update, :destroy ]

  def index
    @rules = Current.family.rules.order(created_at: :desc)
    render layout: "settings"
  end

  def new
    @rule = Current.family.rules.build(
      resource_type: params[:resource_type] || "transaction",
      conditions: [
        Rule::Condition.new(
          condition_type: params[:condition_type] || "transaction_amount",
          value: params[:condition_value]
        )
      ],
      actions: [
        Rule::Action.new(
          action_type: params[:action_type] || "set_transaction_category",
          value: params[:action_value]
        )
      ]
    )
  end

  def create
    @rule = Current.family.rules.build(rule_params)

    if @rule.save
      respond_to do |format|
        format.html { redirect_back_or_to rules_path, notice: "Rule created" }
        format.turbo_stream { stream_redirect_back_or_to rules_path, notice: "Rule created" }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @rule.update(rule_params)
      respond_to do |format|
        format.html { redirect_back_or_to rules_path, notice: "Rule updated" }
        format.turbo_stream { stream_redirect_back_or_to rules_path, notice: "Rule updated" }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @rule.destroy
    redirect_to rules_path, notice: "Rule deleted"
  end

  def destroy_all
    Current.family.rules.destroy_all
    redirect_to rules_path, notice: "All rules deleted"
  end

  private
    def set_rule
      @rule = Current.family.rules.find(params[:id])
    end

    def rule_params
      params.require(:rule).permit(
        :resource_type, :effective_date, :active,
        conditions_attributes: [
          :id, :condition_type, :operator, :value, :_destroy,
          sub_conditions_attributes: [ :id, :condition_type, :operator, :value, :_destroy ]
        ],
        actions_attributes: [
          :id, :action_type, :value, :_destroy
        ]
      )
    end
end
