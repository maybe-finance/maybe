require "ostruct"

Rails.application.configure do
  config.simple_fin = nil

  if ENV["SIMPLE_FIN_ACCESS_URL"].present?
    config.simple_fin = OpenStruct.new()
    config.simple_fin["ACCESS_URL"] = ENV["SIMPLE_FIN_ACCESS_URL"]
  end
end
