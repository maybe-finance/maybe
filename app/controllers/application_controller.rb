class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  private

  def authenticate_user!
    redirect_to new_session_path unless user_signed_in?
  end

  def current_user
    Current.user || authenticate_user_from_session
  end
  helper_method :current_user

  def current_family
    current_user.family
  end
  helper_method :current_family

  def authenticate_user_from_session
    User.find_by(id: session[:user_id])
  end  

  def user_signed_in?
    current_user.present?
  end
  helper_method :user_signed_in?

  def login(user)
    Current.user = user
    reset_session
    session[:user_id] = user.id
  end

  def logout
    Current.user = nil
    reset_session
  end
end
