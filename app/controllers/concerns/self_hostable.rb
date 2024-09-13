module SelfHostable
  extend ActiveSupport::Concern

  included do
    helper_method :self_hosted?, :self_hosted_first_login?
  end

  private
    def self_hosted?
      Rails.configuration.app_mode.self_hosted?
    end

    def self_hosted_first_login?
      self_hosted? && User.count.zero?
    end
end
