module Invitable
  extend ActiveSupport::Concern

  included do
    helper_method :invite_code_required?
  end

  private
    def invite_code_required?
      ENV["REQUIRE_INVITE_CODE"] == "true"
    end
end
