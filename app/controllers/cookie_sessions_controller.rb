class CookieSessionsController < ApplicationController
  def update
    save_kv_to_session(
      cookie_session_params[:tab_key],
      cookie_session_params[:tab_value]
    )

    redirect_back_or_to root_path
  end

  private
    def cookie_session_params
      params.require(:cookie_session).permit(:tab_key, :tab_value)
    end

    def save_kv_to_session(key, value)
      raise "Key must be a string" unless key.is_a?(String)
      raise "Value must be a string" unless value.is_a?(String)

      session["custom_#{key}"] = value
    end
end
