# Simple feature guard that renders a 403 Forbidden status with a message
# when the feature is disabled.
#
# Example:
#
# class MessagesController < ApplicationController
#   guard_feature unless: -> { Current.user.ai_enabled? }
# end
#
module FeatureGuardable
  extend ActiveSupport::Concern

  class_methods do
    def guard_feature(**options)
      before_action :guard_feature, **options
    end
  end

  private
    def guard_feature
      render plain: "Feature disabled: #{controller_name}##{action_name}", status: :forbidden
    end
end
