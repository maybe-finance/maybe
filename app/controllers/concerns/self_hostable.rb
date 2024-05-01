module SelfHostable
  extend ActiveSupport::Concern

  included do
    helper_method :self_hosted?
  end

  private
    def self_hosted?
      Rails.configuration.app_mode.self_hosted?
    end
end
