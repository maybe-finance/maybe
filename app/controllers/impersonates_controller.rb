class ImpersonatesController < ApplicationController
  before_action :require_super_admin!, only: :create

  def create
    impersonate User.find(params[:user_id])
    redirect_to root_url
  end

  def destroy
    stop_impersonating
    redirect_to root_url
  end

  private

    def require_super_admin!
      redirect_to root_path unless Current.user.super_admin?
    end
end
