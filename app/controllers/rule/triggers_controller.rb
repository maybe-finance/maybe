class Rule::TriggersController < ApplicationController
  before_action :set_rule
  before_action :set_trigger, only: [ :update, :destroy ]

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

    def set_trigger
      @trigger = @rule.triggers.find(params[:id])
    end

    def trigger_params
      params.require(:trigger).permit(:trigger_type)
    end
end
