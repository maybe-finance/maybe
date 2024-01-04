class OnboardingController < ApplicationController
  before_action :authenticate_user!

  layout 'simple'
  include Wicked::Wizard

  steps :name, :birthday, :location, :currency, :family, :household, :risk, :goals, :agreements, :upgrade, :welcome

  def show
    @user = current_user
    @user.family

    case step
    when :upgrade
      #if current_user.payment_processor.subscribed?
        jump_to(:welcome)
      # else
      #   @user.payment_processor.customer

      #   @session = @user.payment_processor.checkout(
      #     mode: "subscription",
      #     line_items: ENV['STRIPE_PRICE_ID'],
      #     allow_promotion_codes: true
      #   )
      # end
    end
    
    render_wizard
  end

  def update
    @user = current_user

    case step
    when :agreements
      @user.family.agreed = true
      @user.family.agreed_at = Time.now
      @user.family.agreements = {}
      @user.save
    else
      @user.update(user_params)
    end

    render_wizard @user
  end
  
  private
  def user_params
    params.require(:user)
          .permit(:first_name, :last_name, :birthday, family_attributes: [:id, :country, :region, :currency, :name, :household, :risk, :goals, :agreed, :agreed_at, :agreements])
  end
end
