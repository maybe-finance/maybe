class OnboardingsController < ApplicationController
  layout "application"

  before_action :set_user

  def show
  end

  def profile
  end

  def preferences
  end

  private
    def set_user
      @user = Current.user
    end
end
