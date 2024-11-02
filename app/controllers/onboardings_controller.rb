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
      @invitation = Invitation.accepted.most_recent_for_email(Current.user.email)
    end
end
