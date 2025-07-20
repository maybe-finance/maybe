# config/initializers/investment_analytics_providers.rb

# Ensure the InvestmentAnalytics module is loaded
require_relative '../../app/apps/investment_analytics/investment_analytics'
require Rails.root.join('app', 'models', 'provider')
require Rails.root.join('app', 'models', 'provider', 'registry')

# Ensure the FmpProvider class is loaded
require_relative '../../app/apps/investment_analytics/services/investment_analytics/fmp_provider'

# Register the FmpProvider with the Provider::Registry
Provider::Registry.register_provider(:fmp, InvestmentAnalytics::FmpProvider)

Rails.logger.info("Registered InvestmentAnalytics::FmpProvider with Provider::Registry")
