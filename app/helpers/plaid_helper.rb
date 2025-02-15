module PlaidHelper
  def plaid_webhooks_url(region = :us)
    if Rails.env.production?
      region.to_sym == :eu ? webhooks_plaid_eu_url : webhooks_plaid_url
    else
      ENV.fetch("DEV_WEBHOOKS_URL", root_url.chomp("/")) + "/webhooks/plaid#{region.to_sym == :eu ? '_eu' : ''}"
    end
  end
end
