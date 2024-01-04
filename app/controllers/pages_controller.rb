class PagesController < ApplicationController
  include PlaidToken

  before_action :authenticate_user!

  def index
    if current_user.family.agreed == false
      redirect_to onboarding_path(:name)
    elsif !current_user.payment_processor.subscribed?
      #redirect_to onboarding_path(:upgrade)
    end

    # Create a new conversation for the current user if "kind" of "daily_review" for today is not found
    @conversation = Conversation.find_or_create_by(user: current_user, kind: "daily_review", created_at: Date.today.beginning_of_day..Date.today.end_of_day) do |conversation|
      conversation.title = Date.today.strftime("%B %-d, %Y")
      conversation.role = "system"
    end
  end

  def upgrade
    if current_user.present?
      current_user.payment_processor.customer

      @session = current_user.payment_processor.checkout(
        mode: "subscription",
        line_items: ENV['STRIPE_PRICE_ID'],
        allow_promotion_codes: true
      )
    end

    if current_user.payment_processor.subscribed?
      redirect_to root_path
    else
      render layout: 'simple'
    end
  end

  def settings
    @user = current_user
  end

  def settings_update
    @user = current_user

    if @user.update(user_params)
      redirect_to settings_path, notice: "Settings updated successfully."
    else
      render :settings
    end
  end
end
