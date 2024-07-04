if ENV["COVERAGE"] == "true"
  require "simplecov"
  SimpleCov.start "rails" do
    enable_coverage :branch
  end
end

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"

# See .env.test.example for more configurable variables
ENV["SELF_HOSTING_ENABLED"] = "false"
ENV["UPGRADES_ENABLED"] = "false"

# Fixes Segfaults on M1 Macs when running tests in parallel (temporary workaround)
# https://github.com/ged/ruby-pg/issues/538#issuecomment-1591629049
ENV["PGGSSENCMODE"] = "disable"

require "rails/test_help"
require "minitest/mock"
require "minitest/autorun"
require "mocha/minitest"

VCR.configure do |config|
  config.cassette_library_dir = "test/vcr_cassettes"
  config.hook_into :webmock
  config.ignore_localhost = true
  config.default_cassette_options = { erb: true }
  config.filter_sensitive_data("<SYNTH_API_KEY>") { ENV["SYNTH_API_KEY"] }
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
      post session_path, params: { email: user.email, password: "password" }
    end

    def with_env_overrides(overrides = {}, &block)
      ClimateControl.modify(**overrides, &block)
    end

    def with_self_hosting
      Rails.configuration.stubs(:app_mode).returns("self_hosted".inquiry)
      yield
    end

    def with_synth(&block)
      with_env_overrides SYNTH_API_KEY: synth_api_key, &block
    end

    def with_data_providers_disabled(&block)
      with_env_overrides SYNTH_API_KEY: nil, &block
    end

    def synth_api_key
      # Live key is only needed for generating VCR cassette fixtures one time
      key = ENV["SYNTH_API_KEY"] || "foo"
    end
  end
end

Dir[Rails.root.join("test", "interfaces", "**", "*.rb")].each { |f| require f }
