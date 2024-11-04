if ENV.fetch("OPENAI_ACCESS_TOKEN", nil).present?
  OpenAI.configure do |config|
    config.access_token = ENV.fetch("OPENAI_ACCESS_TOKEN")
    config.log_errors = true if Rails.env.development?
  end
end
