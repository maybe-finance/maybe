class SubscriptionsController < ApplicationController
  # Disables subscriptions for self hosted instances
  guard_feature if: -> { self_hosted? }

  # Upgrade page for unsubscribed users
  def upgrade
    render layout: "onboardings"
  end

  def start_trial
    if Current.family.trial_started_at.present?
      redirect_to root_path, alert: "You've already started or completed your trial"
    else
      Family.transaction do
        Current.family.update(trial_started_at: Time.current)
        Current.user.update(onboarded_at: Time.current)
      end

      redirect_to root_path, notice: "Your trial has started"
    end
  end

  def new
    price_map = {
      monthly: ENV["STRIPE_MONTHLY_PRICE_ID"],
      annual: ENV["STRIPE_ANNUAL_PRICE_ID"]
    }

    price_id = price_map[(params[:plan] || :monthly).to_sym]

    unless Current.family.existing_customer?
      customer = stripe.create_customer(
        email: Current.family.primary_user.email,
        metadata: { family_id: Current.family.id }
      )

      Current.family.update(stripe_customer_id: customer.id)
    end

    checkout_session_url = stripe.get_checkout_session_url(
      price_id,
      customer_id: Current.family.stripe_customer_id,
      success_url: success_subscription_url + "?session_id={CHECKOUT_SESSION_ID}",
      cancel_url: upgrade_subscription_url(plan: params[:plan])
    )

    redirect_to checkout_session_url, allow_other_host: true, status: :see_other
  end

  def show
    portal_session_url = stripe.get_billing_portal_session_url(
      Current.family.stripe_customer_id,
      return_url: settings_billing_url
    )

    redirect_to portal_session_url, allow_other_host: true, status: :see_other
  end

  def success
    checkout_session = stripe.retrieve_checkout_session(params[:session_id])
    Current.session.update(subscribed_at: Time.at(checkout_session.created))
    redirect_to root_path, notice: "You have successfully subscribed to Maybe+."
  rescue Stripe::InvalidRequestError
    redirect_to settings_billing_path, alert: "Something went wrong processing your subscription. Please contact us to get this fixed."
  end

  private
    def stripe
      @stripe ||= Provider::Registry.get_provider(:stripe)
    end
end
