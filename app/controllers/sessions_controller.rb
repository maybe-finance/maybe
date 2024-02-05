class SessionsController < ApplicationController
  layout "auth"

  def new
  end

  def create
    if user = User.authenticate_by(email: params[:email], password: params[:password])
      login user
      redirect_to root_path
    else
      flash.now[:alert] = t(".invalid_credentials")
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    logout
    redirect_to root_path, notice: t(".logout_successful")
  end
end
