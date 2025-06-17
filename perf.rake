# Must be in root of repo for derailed_benchmarks to read the benchmark file

require 'bundler'
Bundler.setup

require 'derailed_benchmarks'
require 'derailed_benchmarks/tasks'

# Custom auth helper for Maybe's session-based authentication
class CustomAuth < DerailedBenchmarks::AuthHelper
  def setup
    # No setup needed
  end

  def call(env)
    # Make sure this user is created in the DB with realistic data before running benchmarks
    user = User.find_by!(email: "user@maybe.local")

    Rails.logger.debug "Found user for benchmarking: #{user.email}"

    # Mimic the way Rails handles browser cookies
    session = user.sessions.create!
    key_generator = Rails.application.key_generator
    secret = key_generator.generate_key('signed cookie')
    verifier = ActiveSupport::MessageVerifier.new(secret)
    signed_value = verifier.generate(session.id)

    env['HTTP_COOKIE'] = "session_token=#{signed_value}"

    Rails.logger.debug "Setting up session for user: #{user.email}"

    app.call(env)
  end
end

# Tells derailed_benchmarks to use our custom auth helper
DerailedBenchmarks.auth = CustomAuth.new
