ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
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
  config.filter_sensitive_data("<EXCHANGE_RATES_API_KEY>") { ENV["EXCHANGE_RATES_API_KEY"] }
  config.filter_sensitive_data("<MERCHANT_DATA_API_KEY>") { ENV["MERCHANT_DATA_API_KEY"] }
  config.filter_sensitive_data("<REAL_ESTATE_VALUATIONS_API_KEY>") { ENV["REAL_ESTATE_VALUATIONS_API_KEY"] }
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
    def sign_in(user)
      post session_path, params: { email: user.email, password: "password" }
    end

    def swap_provider_for(concept, to:)
      modified_providers = Rails.application.config_for("data_providers").tap do |providers|
        providers[concept.to_sym] = { provider: to.to_s }
      end

      Rails.application.stubs(:config_for).with("data_providers").returns(modified_providers)

      yield
    end
  end
end

Dir[Rails.root.join("test", "interfaces", "**", "*.rb")].each { |f| require f }
