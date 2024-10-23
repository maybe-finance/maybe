module Onboardable
  extend ActiveSupport::Concern

  included do
    after_action :ensure_onboarded
  end

  private

    def ensure_onboarded
      return if !Current.user || Current.user.onboarding.complete? || request.path == onboarding_path

      redirect_to onboarding_path
    end
end
