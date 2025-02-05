Rails.application.configure do
  config.plaid = nil
  config.plaid_eu = nil

  if ENV["PLAID_CLIENT_ID"].present? && ENV["PLAID_SECRET"].present?
    config.plaid = Plaid::Configuration.new
    config.plaid.server_index = Plaid::Configuration::Environment[ENV["PLAID_ENV"] || "sandbox"]
    config.plaid.api_key["PLAID-CLIENT-ID"] = ENV["PLAID_CLIENT_ID"]
    config.plaid.api_key["PLAID-SECRET"] = ENV["PLAID_SECRET"]
  end

  if ENV["PLAID_EU_CLIENT_ID"].present? && ENV["PLAID_EU_SECRET"].present?
    config.plaid_eu = Plaid::Configuration.new
    config.plaid_eu.server_index = Plaid::Configuration::Environment[ENV["PLAID_ENV"] || "sandbox"]
    config.plaid_eu.api_key["PLAID-CLIENT-ID"] = ENV["PLAID_EU_CLIENT_ID"]
    config.plaid_eu.api_key["PLAID-SECRET"] = ENV["PLAID_EU_SECRET"]
  end
end
