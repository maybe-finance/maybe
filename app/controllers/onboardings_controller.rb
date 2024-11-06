class OnboardingsController < ApplicationController
  layout "application"
  before_action :set_user
  before_action :load_invitation

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

    def load_invitation
      @invitation = Current.family.invitations.accepted.find_by(email: Current.user.email)
    end
end
