module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
    after_action :set_last_login_at
  end

  class_methods do
    def skip_authentication(**options)
      skip_before_action :authenticate_user!, **options
      skip_after_action :set_last_login_at, **options
    end
  end

  private

  def authenticate_user!
    if user = User.find_by(id: session[:user_id])
      Current.user = user
    else
      redirect_to new_session_url
    end
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

  def set_last_login_at
    Current.user.update(last_login_at: DateTime.now)
  end
end
