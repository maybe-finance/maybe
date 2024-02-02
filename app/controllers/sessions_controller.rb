class SessionsController < ApplicationController
  layout "auth"

  def new
  end

  def create
    if user = User.authenticate_by(email: params[:email], password: params[:password])
      login user
      redirect_to root_path
    else
      flash.now[:alert] = "Invalid email or password."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    logout
    redirect_to root_path, notice: "You have signed out successfully."
  end
end
