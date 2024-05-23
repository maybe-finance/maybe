Rails.application.config.to_prepare do
  Provider::Synth.configure do |config|
    config.api_key = ENV["SYNTH_API_KEY"]
  end
end
