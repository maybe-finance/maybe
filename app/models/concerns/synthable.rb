module Synthable
  extend ActiveSupport::Concern

  class_methods do
    def synth_usage
      synth_client&.usage
    end

    def synth_overage?
      synth_usage&.usage&.utilization.to_i >= 100
    end

    def synth_healthy?
      synth_client&.healthy?
    end

    def synth_client
      api_key = ENV.fetch("SYNTH_API_KEY", Setting.synth_api_key)

      return nil unless api_key.present?

      Provider::Synth.new(api_key)
    end
  end

  def synth_client
    self.class.synth_client
  end
end
