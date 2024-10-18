class ImpersonationSessionsController < ApplicationController
  before_action :require_super_admin!, only: [ :create, :join, :leave ]
  before_action :set_impersonation_session, only: [ :approve, :reject, :complete ]

  def create
    Current.true_user.request_impersonation_for(session_params[:impersonated_id])
    redirect_to root_path, notice: t(".success")
  end

  def join
    @impersonation_session = Current.true_user.impersonator_support_sessions.find_by(id: params[:impersonation_session_id])
    Current.session.update!(active_impersonator_session: @impersonation_session)
    redirect_to root_path, notice: t(".success")
  end

  def leave
    Current.session.update!(active_impersonator_session: nil)
    redirect_to root_path, notice: t(".success")
  end

  def approve
    raise_unauthorized! unless @impersonation_session.impersonated == Current.true_user

    @impersonation_session.approve!
    redirect_to root_path, notice: t(".success")
  end

  def reject
    raise_unauthorized! unless @impersonation_session.impersonated == Current.true_user

    @impersonation_session.reject!
    redirect_to root_path, notice: t(".success")
  end

  def complete
    @impersonation_session.complete!
    redirect_to root_path, notice: t(".success")
  end

  private
    def session_params
      params.require(:impersonation_session).permit(:impersonated_id)
    end

    def set_impersonation_session
      @impersonation_session =
        Current.true_user.impersonated_support_sessions.find_by(id: params[:id]) ||
        Current.true_user.impersonator_support_sessions.find_by(id: params[:id])
    end

    def require_super_admin!
      raise_unauthorized! unless Current.true_user&.super_admin?
    end

    def raise_unauthorized!
      raise ActionController::RoutingError.new("Not Found")
    end
end
