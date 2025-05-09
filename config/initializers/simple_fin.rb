require "ostruct"

Rails.application.configure do
  config.simple_fin = nil

  if ENV["SIMPLE_FIN_ACCESS_URL"].present?
    config.simple_fin = OpenStruct.new()
    config.simple_fin["ACCESS_URL"] = ENV["SIMPLE_FIN_ACCESS_URL"]
    config.simple_fin["UPDATE_CRON"] = ENV["SIMPLE_FIN_UPDATE_CRON"]
    # Fallback
    config.simple_fin["UPDATE_CRON"] = "0 6 * * *" if config.simple_fin["UPDATE_CRON"].nil?
  end
end
