require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Maybe
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    config.action_mailer.delivery_method = :postmark

    config.action_mailer.postmark_settings = {
      api_token: ENV['POSTMARK_API_TOKEN']
    }

    config.active_job.queue_adapter = :good_job
    config.good_job.execution_mode = :async

    config.active_record.writing_role = :primary
    config.active_record.reading_role = :primary_replica
  end
end
