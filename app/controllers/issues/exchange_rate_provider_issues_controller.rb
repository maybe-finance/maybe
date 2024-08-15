class Issues::ExchangeRateProviderIssuesController < ApplicationController
  def update
    Setting.synth_api_key = exchange_rate_params[:synth_api_key]
  end

  private

    def exchange_rate_params
      params.require(:issue).permit(:synth_api_key)
    end
end
