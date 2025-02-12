class Settings::BillingsController < ApplicationController
  def show
    @user = Current.user
  end
end
