module Onboarding
  extend ActiveSupport::Concern

  included do
    before_action :ensure_onboarded
  end

  private

    def ensure_onboarded
      return unless Current.user

      unless Current.user.onboarded? || ignore_paths.include?(request.path)
        redirect_to onboarding_path
      end
    end

    def ignore_paths
      [ onboarding_path, user_path(Current.user) ]
    end
end
