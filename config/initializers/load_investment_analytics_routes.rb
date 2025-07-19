# config/initializers/load_investment_analytics_routes.rb

# Conditionally load Investment Analytics routes if the app is enabled.
# This ensures the routes are only defined when the feature is active.

if ENV['ENABLE_INVESTMENT_ANALYTICS_APP'] == 'true'
  # Directly require the routes file
  require Rails.root.join('config', 'routes', 'investment_analytics.rb')

  Rails.logger.info("Investment Analytics routes loaded.")
else
  Rails.logger.info("Investment Analytics app is disabled. Routes not loaded.")
end