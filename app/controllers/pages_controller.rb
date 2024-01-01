class PagesController < ApplicationController
  before_action :authenticate_user!, only: [:home]

  def home
  end
end
