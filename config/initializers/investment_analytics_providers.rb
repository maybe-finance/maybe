# config/initializers/investment_analytics_providers.rb

# Ensure the InvestmentAnalytics module is loaded
require_relative '../../app/apps/investment_analytics/investment_analytics'

# Ensure the FmpProvider class is loaded
require_relative '../../app/apps/investment_analytics/services/investment_analytics/fmp_provider'

# Register the FmpProvider with the Provider::Registry
Provider::Registry.register_provider(:fmp, InvestmentAnalytics::FmpProvider)

Rails.logger.info("Registered InvestmentAnalytics::FmpProvider with Provider::Registry")
