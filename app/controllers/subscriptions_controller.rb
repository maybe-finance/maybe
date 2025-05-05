class SubscriptionsController < ApplicationController
  # Disables subscriptions for self hosted instances
  guard_feature if: -> { self_hosted? }

  # Upgrade page for unsubscribed users
  def upgrade
    if Current.family.subscription&.active?
      redirect_to root_path, notice: "You are already subscribed."
    else
      @plan = params[:plan] || "annual"
      render layout: "onboardings"
    end
  end

  def new
    checkout_session_url = subscription_manager.checkout_session_url(
      plan: params[:plan],
      email: Current.family.billing_email,
      family_id: Current.family.id
    )

    redirect_to checkout_session_url, allow_other_host: true, status: :see_other
  end

  # Only used for managing our "offline" trials.  Paid subscriptions are handled in success callback of checkout session
  def create
    if Current.family.can_start_trial?
      Current.family.start_trial_subscription!
      redirect_to root_path, notice: "Welcome to Maybe!"
    else
      redirect_to root_path, alert: "You have already started or completed a trial. Please upgrade to continue."
    end
  end

  def show
    portal_session_url = subscription_manager.billing_portal_url_for(
      Current.family.stripe_customer_id
    )

    redirect_to portal_session_url, allow_other_host: true, status: :see_other
  end

  # Stripe redirects here after a successful checkout session and passes the session ID in the URL
  def success
    checkout_result = subscription_manager.get_checkout_result(params[:session_id])

    if checkout_result.success?
      Current.family.start_subscription!(checkout_result.subscription_id)
      redirect_to root_path, notice: "Welcome to Maybe!  Your subscription has been created."
    else
      redirect_to root_path, alert: "Something went wrong processing your subscription. Please contact us to get this fixed."
    end
  end

  private
    def subscription_manager
      @subscription_manager ||= SubscriptionManager.new(
        upgrade_url: upgrade_subscription_url,
        checkout_success_url: success_subscription_url,
        billing_url: settings_billing_url
      )
    end
end
