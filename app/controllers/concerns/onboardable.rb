module Onboardable
  extend ActiveSupport::Concern

  included do
    before_action :redirect_to_onboarding, if: :needs_onboarding?
  end

  private
    def redirect_to_onboarding
      redirect_to onboarding_path
    end

    def needs_onboarding?
      Current.user && Current.user.onboarded_at.blank? &&
        !%w[/users /onboarding /sessions].any? { |path| request.path.start_with?(path) }
    end
end
