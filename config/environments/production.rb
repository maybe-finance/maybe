require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  # Ensures that a master key has been made available in ENV["RAILS_MASTER_KEY"], config/master.key, or an environment
  # key such as config/credentials/production.key. This key is used to decrypt credentials (and other encrypted files).
  # config.require_master_key = true

  # Disable serving static files from `public/`, relying on NGINX/Apache to do so instead.
  # config.public_file_server.enabled = false

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for Apache
  # config.action_dispatch.x_sendfile_header = "X-Accel-Redirect" # for NGINX

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = ENV.fetch("ACTIVE_STORAGE_SERVICE", "local").to_sym

  # Set Active Storage URL expiration time to 7 days
  config.active_storage.urls_expire_in = 7.days

  # Mount Action Cable outside main process or domain.
  # config.action_cable.mount_path = nil
  # config.action_cable.url = "wss://example.com/cable"
  # config.action_cable.allowed_request_origins = [ "http://example.com", /http:\/\/example.*/ ]

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = ActiveModel::Type::Boolean.new.cast(ENV.fetch("RAILS_FORCE_SSL", true))

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  # Can be used together with config.force_ssl for Strict-Transport-Security and secure cookies.
  config.assume_ssl = ActiveModel::Type::Boolean.new.cast(ENV.fetch("RAILS_ASSUME_SSL", true))

  # Log to Logtail if API key is present, otherwise log to STDOUT
  base_logger = if ENV["LOGTAIL_API_KEY"].present? && ENV["LOGTAIL_INGESTING_HOST"].present?
    Logtail::Logger.create_default_logger(
      ENV["LOGTAIL_API_KEY"],
      ingesting_host: ENV["LOGTAIL_INGESTING_HOST"]
    )
  else
    ActiveSupport::Logger.new(STDOUT)
      .tap { |logger| logger.formatter = ::Logger::Formatter.new }
  end

  config.logger = ActiveSupport::TaggedLogging.new(base_logger)

  # Prepend all log lines with the following tags.
  config.log_tags = [ :request_id ]

  # "info" includes generic and useful information about system operation, but avoids logging too much
  # information to avoid inadvertent exposure of personally identifiable information (PII). If you
  # want to log everything, set the level to "debug".
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  if ENV["CACHE_REDIS_URL"].present?
    config.cache_store = :redis_cache_store, { url: ENV["CACHE_REDIS_URL"] }
  end

  config.action_mailer.perform_caching = false
  config.action_mailer.deliver_later_queue_name = :high_priority
  config.action_mailer.default_url_options = { host: ENV["APP_DOMAIN"] }
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address:   ENV["SMTP_ADDRESS"],
    port:      ENV["SMTP_PORT"],
    user_name: ENV["SMTP_USERNAME"],
    password:  ENV["SMTP_PASSWORD"],
    tls:       ENV["SMTP_TLS_ENABLED"] == "true"
  }

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Enable DNS rebinding protection and other `Host` header attacks.
  # config.hosts = [
  #   "example.com",     # Allow requests from example.com
  #   /.*\.example\.com/ # Allow requests from subdomains like `www.example.com`
  # ]
  # Skip DNS rebinding protection for the default health check endpoint.
  # config.host_authorization = { exclude: ->(request) { request.path == "/up" } }

  # set REDIS_URL for Sidekiq to use Redis
  config.active_job.queue_adapter = :sidekiq
end
