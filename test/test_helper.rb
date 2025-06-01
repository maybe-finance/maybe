if ENV["COVERAGE"] == "true"
  require "simplecov"
  SimpleCov.start "rails" do
    enable_coverage :branch
  end
end

require_relative "../config/environment"

ENV["RAILS_ENV"] ||= "test"

# Set Plaid to sandbox mode for tests
ENV["PLAID_ENV"] = "sandbox"
ENV["PLAID_CLIENT_ID"] ||= "test_client_id"
ENV["PLAID_SECRET"] ||= "test_secret"

# Fixes Segfaults on M1 Macs when running tests in parallel (temporary workaround)
ENV["PGGSSENCMODE"] = "disable"

require "rails/test_help"
require "minitest/mock"
require "minitest/autorun"
require "mocha/minitest"
require "aasm/minitest"

VCR.configure do |config|
  config.cassette_library_dir = "test/vcr_cassettes"
  config.hook_into :webmock
  config.ignore_localhost = true
  config.default_cassette_options = { erb: true }
  config.filter_sensitive_data("<SYNTH_API_KEY>") { ENV["SYNTH_API_KEY"] }
  config.filter_sensitive_data("<OPENAI_ACCESS_TOKEN>") { ENV["OPENAI_ACCESS_TOKEN"] }
  config.filter_sensitive_data("<OPENAI_ORGANIZATION_ID>") { ENV["OPENAI_ORGANIZATION_ID"] }
  config.filter_sensitive_data("<STRIPE_SECRET_KEY>") { ENV["STRIPE_SECRET_KEY"] }
  config.filter_sensitive_data("<STRIPE_WEBHOOK_SECRET>") { ENV["STRIPE_WEBHOOK_SECRET"] }
  config.filter_sensitive_data("<PLAID_CLIENT_ID>") { ENV["PLAID_CLIENT_ID"] }
  config.filter_sensitive_data("<PLAID_SECRET>") { ENV["PLAID_SECRET"] }
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors) unless ENV["DISABLE_PARALLELIZATION"] == "true"

    # https://github.com/simplecov-ruby/simplecov/issues/718#issuecomment-538201587
    if ENV["COVERAGE"] == "true"
      parallelize_setup do |worker|
        SimpleCov.command_name "#{SimpleCov.command_name}-#{worker}"
      end

      parallelize_teardown do |worker|
        SimpleCov.result
      end
    end

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
    def sign_in(user)
      post sessions_path, params: { email: user.email, password: user_password_test }
    end

    def with_env_overrides(overrides = {}, &block)
      ClimateControl.modify(**overrides, &block)
    end

    def with_self_hosting
      Rails.configuration.stubs(:app_mode).returns("self_hosted".inquiry)
      yield
    end

    def user_password_test
      "maybetestpassword817983172"
    end
  end
end

Dir[Rails.root.join("test", "interfaces", "**", "*.rb")].each { |f| require f }
