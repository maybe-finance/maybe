class FetchSecurityInfoJob < ApplicationJob
  queue_as :latency_low

  def perform(security_id)
    return unless Security.security_info_provider.present?

    security = Security.find(security_id)

    security_info_response = Security.security_info_provider.fetch_security_info(
      ticker: security.ticker,
      mic_code: security.exchange_mic
    )

    security.update(
      name: security_info_response.info.dig("name")
    )
  end
end
