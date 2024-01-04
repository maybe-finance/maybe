Sentry.init do |config|
  config.dsn = 'https://1789da52e499454c8eb0b2d570a7cb56@o675109.ingest.sentry.io/4504980729364480'
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]
  config.enabled_environments = %w[production]

  # Set traces_sample_rate to 1.0 to capture 100%
  # of transactions for performance monitoring.
  # We recommend adjusting this value in production.
  config.traces_sample_rate = 1.0
  # or
  config.traces_sampler = lambda do |context|
    true
  end
end