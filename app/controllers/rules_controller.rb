class RulesController < ApplicationController
  include StreamExtensions

  before_action :set_rule, only: [  :edit, :update, :destroy, :apply, :confirm ]

  def index
    @rules = Current.family.rules.order(created_at: :desc)
    render layout: "settings"
  end

  def new
    @rule = Current.family.rules.build(
      resource_type: params[:resource_type] || "transaction",
    )
  end

  def create
    @rule = Current.family.rules.build(rule_params)

    if @rule.save
      redirect_to confirm_rule_path(@rule)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def apply
    @rule.update!(active: true)
    @rule.apply_later(ignore_attribute_locks: true)
    redirect_back_or_to rules_path, notice: "#{@rule.resource_type.humanize} rule activated"
  end

  def confirm
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
