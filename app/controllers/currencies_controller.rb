class CurrenciesController < ApplicationController
  def show
    @currency = Money::Currency.all_instances.find { |currency| currency.iso_code == params[:id] }
    render json: { step: @currency.step, placeholder: Money.new(0, @currency).format }
  end
end
