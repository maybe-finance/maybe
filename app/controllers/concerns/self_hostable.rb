module SelfHostable
  extend ActiveSupport::Concern

  included do
    helper_method :self_hosted?
  end

  private
    def self_hosted?
      ENV["SELF_HOSTING_ENABLED"] == "true"
    end
end
