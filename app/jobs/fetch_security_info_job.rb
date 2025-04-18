class FetchSecurityInfoJob < ApplicationJob
  queue_as :low_priority

  def perform(security_id)
    return unless Security.provider.present?

    security = Security.find(security_id)

    params = {
      ticker: security.ticker
    }
    params[:mic_code] = security.exchange_mic if security.exchange_mic.present?
    params[:operating_mic] = security.exchange_operating_mic if security.exchange_operating_mic.present?

    security_info_response = Security.provider.fetch_security_info(**params)

    security.update(
      name: security_info_response.info.dig("name")
    )
  end
end
