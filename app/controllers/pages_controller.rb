class PagesController < ApplicationController
  before_action :authenticate_user!

  def dashboard
    @account_groups = Current.user.family.accounts.by_type
  end
end
