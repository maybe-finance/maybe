module Impersonatable
  extend ActiveSupport::Concern

  included do
    after_action :create_impersonation_session_log
  end

  private
    def create_impersonation_session_log
      return unless Current.session&.active_impersonator_session.present?

      Current.session.active_impersonator_session.logs.create!(
        controller: controller_name,
        action: action_name,
        path: request.fullpath,
        method: request.method,
        ip_address: request.ip,
        user_agent: request.user_agent
      )
    end
end
