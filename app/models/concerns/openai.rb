module OpenAI
  extend ActiveSupport::Concern

  class_methods do
    def openai_client
      api_key = ENV.fetch("OPENAI_ACCESS_TOKEN", Setting.openai_access_token)

      return nil unless api_key.present?

      OpenAI::Client.new(access_token: api_key)
    end
  end

  def openai_client
    self.class.openai_client
  end
end
