class CurrentSessionsController < ApplicationController
  def update
    if session_params[:tab_key].present? && session_params[:tab_value].present?
      Current.session.set_preferred_tab(session_params[:tab_key], session_params[:tab_value])
    end

    head :ok
  end

  private
    def session_params
      params.require(:current_session).permit(:tab_key, :tab_value)
    end
end
