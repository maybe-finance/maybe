class Issue::ExchangeRateProviderMissingsController < ApplicationController
  before_action :set_issue, only: :update

  def update
    Setting.synth_api_key = exchange_rate_params[:synth_api_key]
    account = @issue.issuable
    account.sync_later
    redirect_back_or_to account.accountable
  end

  private

    def set_issue
      @issue = Current.family.issues.find(params[:id])
    end

    def exchange_rate_params
      params.require(:issue_exchange_rate_provider_missing).permit(:synth_api_key)
    end
end
