class Rule::ActionsController < ApplicationController
  before_action :set_rule
  before_action :set_action, only: [ :update, :destroy ]

  def create
  end

  def update
  end

  def destroy
  end

  private

    def set_rule
      @rule = Current.family.rules.find(params[:rule_id])
    end

    def set_action
      @action = @rule.actions.find(params[:id])
    end

    def action_params
      params.require(:action).permit(:action_type)
    end
end
