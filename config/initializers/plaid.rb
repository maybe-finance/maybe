Rails.application.configure do
  config.plaid = Plaid::Configuration.new
  config.plaid.server_index = Plaid::Configuration::Environment[ENV["PLAID_ENV"] || "sandbox"]
  config.plaid.api_key["PLAID-CLIENT-ID"] = ENV["PLAID_CLIENT_ID"]
  config.plaid.api_key["PLAID-SECRET"] = ENV["PLAID_SECRET"]
end
