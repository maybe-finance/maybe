module Impersonatable
  extend ActiveSupport::Concern

  included do
    after_action :create_impersonation_session_log, if: :impersonating?
  end

  private
    def create_impersonation_session_log
      if impersonating?
        ImpersonationSessionLog.create!(
          impersonation_session: Current.impersonation_session,
          controller: controller_name,
          action: action_name,
          path: request.fullpath,
          method: request.method,
          ip_address: request.ip,
          user_agent: request.user_agent
        )
      end
    end
end
