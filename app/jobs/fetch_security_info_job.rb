class FetchSecurityInfoJob < ApplicationJob
  queue_as :default

  def perform(security_id)
    return unless Security.security_info_provider.present?

    security = Security.find(security_id)

    security_info_response = Security.security_info_provider.fetch_security_info(
      ticker: security.ticker,
      mic_code: security.exchange_mic
    )

    security.update(
      name: security_info_response.info.dig("name"),
      exchange_acronym: security_info_response.info.dig("exchange", "acronym"),
      country_code: security_info_response.info.dig("exchange", "country_code")
    )
  end
end
