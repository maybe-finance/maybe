class ApplicationController < ActionController::Base
  #before_action :set_checkout_session
  #before_action :set_portal_session
  
  helper_method :current_family

  def set_portal_session
    if current_user.present?
      @portal_session = current_user.payment_processor.billing_portal
    end
  end

  def set_checkout_session
    if current_user.present?
      current_user.payment_processor.customer

      @session = current_user.payment_processor.checkout(
        mode: "subscription",
        line_items: ENV['STRIPE_PRICE_ID'],
        allow_promotion_codes: true
      )
    end
  end

  def current_family
    current_user.family if current_user
  end
end
