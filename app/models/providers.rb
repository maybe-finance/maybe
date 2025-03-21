module Providers
  module_function

  def synth
    api_key = ENV.fetch("SYNTH_API_KEY", Setting.synth_api_key)

    return nil unless api_key.present?

    Provider::Synth.new(api_key)
  end

  def plaid_us
    config = Rails.application.config.plaid

    return nil unless config.present?

    Provider::Plaid.new(config, region: :us)
  end

  def plaid_eu
    config = Rails.application.config.plaid_eu

    return nil unless config.present?

    Provider::Plaid.new(config, region: :eu)
  end

  def github
    Provider::Github.new
  end

  def openai
    access_token = ENV.fetch("OPENAI_ACCESS_TOKEN", Setting.openai_access_token)

    return nil unless access_token.present?

    Provider::OpenAI.new(access_token)
  end
end
