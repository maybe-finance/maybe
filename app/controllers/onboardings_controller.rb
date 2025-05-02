class OnboardingsController < ApplicationController
  layout "wizard"

  before_action :set_user
  before_action :load_invitation

  def show
  end

  def preferences
  end

  def trial
  end

  private
    def set_user
      @user = Current.user
    end

    def load_invitation
      @invitation = Current.family.invitations.accepted.find_by(email: Current.user.email)
    end
end
