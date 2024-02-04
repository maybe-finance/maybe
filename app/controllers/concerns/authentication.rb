module Authentication
  extend ActiveSupport::Concern

  included do
    helper_method :user_signed_in?
  end

  private

  def authenticate_user!
    if user = User.find_by(id: session[:user_id])
      Current.user = user
    else
      redirect_to new_session_url
    end
  end

  def user_signed_in?
    Current.user.present?
  end

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
