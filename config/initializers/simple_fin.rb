
class SimpleFinConfig
  attr_accessor :access_url, :rate_limit, :look_back_days

  def initialize
    @rate_limit = 24
    @look_back_days = 7
  end
end

Rails.application.configure do
  config.simple_fin = nil

  # We use the access URL as the base of if we want to run SimpleFIN or not
  if ENV["SIMPLE_FIN_ACCESS_URL"].present?

    sf_config = SimpleFinConfig.new
    sf_config.access_url = ENV["SIMPLE_FIN_ACCESS_URL"]
    sf_config.rate_limit = ENV["SIMPLE_FIN_RATE_LIMIT"].to_i if ENV["SIMPLE_FIN_RATE_LIMIT"].present?
    sf_config.look_back_days = ENV["SIMPLE_FIN_LOOK_BACK_DAYS"].to_i if ENV["SIMPLE_FIN_LOOK_BACK_DAYS"].present?

    config.simple_fin = sf_config
  end
end
