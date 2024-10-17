class ImpersonationSessionsController < ApplicationController
  before_action :require_super_admin!, only: [ :start, :end ]
  before_action :set_impersonation_session, only: [ :approve, :reject, :complete ]

  def create
    Current.user.request_impersonation_for(params[:impersonated_id])
    redirect_to root_path, notice: "Request sent to user.  Waiting for approval."
  end

  def start
    impersonation_session = ImpersonationSession.find(params[:impersonation_session_id])
    impersonate User.find(impersonation_session.impersonated_id)
    redirect_to root_path, notice: "Session started"
  end

  def end
    stop_impersonating
    redirect_to root_path, notice: "Session ended"
  end

  def remove
    stop_impersonating
    Current.impersonation_session.complete!
    redirect_to root_path, notice: "Session ended"
  end

  def approve
    @impersonation_session.approve!
    redirect_to root_path, notice: "Request approved"
  end

  def reject
    @impersonation_session.reject!
    redirect_to root_path, notice: "Request rejected"
  end

  def complete
    @impersonation_session.complete!
    redirect_to root_path, notice: "Session ended"
  end

  private
    def set_impersonation_session
      @impersonation_session = ImpersonationSession
        .where(impersonated: Current.user, status: [ :pending, :in_progress ])
        .first

      redirect_to root_path, alert: "You are not authorized to perform this action." unless @impersonation_session
    end

    def require_super_admin!
      redirect_to root_path unless Current.true_user.super_admin?
    end
end
