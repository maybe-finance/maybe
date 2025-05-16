
class SimpleFinConfig
  attr_accessor :access_url, :rate_limit, :max_history_days

  def initialize
    @rate_limit = 24
    # TODO
    @max_history_days = 1 # Was a constant, now part of config
  end
end

Rails.application.configure do
  config.simple_fin = nil

  # We use the access URL as the base of if we want to run SimpleFIN or not
  if ENV["SIMPLE_FIN_ACCESS_URL"].present?

    sf_config = SimpleFinConfig.new
    sf_config.access_url = ENV["SIMPLE_FIN_ACCESS_URL"]
    sf_config.rate_limit = ENV["SIMPLE_FIN_RATE_LIMIT"].to_i if ENV["SIMPLE_FIN_RATE_LIMIT"].present?

    config.simple_fin = sf_config
  end
end
