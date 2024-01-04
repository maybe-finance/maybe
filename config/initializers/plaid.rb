require 'plaid'

configuration = Plaid::Configuration.new
configuration.server_index = Plaid::Configuration::Environment[ENV['PLAID_ENVIRONMENT']]
configuration.api_key["PLAID-CLIENT-ID"] = ENV['PLAID_CLIENT_ID']
configuration.api_key["PLAID-SECRET"] = ENV['PLAID_SECRET']

$plaid_api_client = Plaid::PlaidApi.new(Plaid::ApiClient.new(configuration))