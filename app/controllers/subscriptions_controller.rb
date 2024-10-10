class SubscriptionsController < ApplicationController
  def new
    client = Stripe::StripeClient.new(ENV["STRIPE_SECRET_KEY"])

    if Current.family.stripe_customer_id.blank?
      customer = client.v1.customers.create(
        email: Current.family.primary_user.email,
        metadata: { family_id: Current.family.id }
      )
      Current.family.update(stripe_customer_id: customer.id)
    end

    session = client.v1.checkout.sessions.create({
      customer: Current.family.stripe_customer_id,
      line_items: [ {
        price: ENV["STRIPE_PLAN_ID"],
        quantity: 1
      } ],
      mode: "subscription",
      allow_promotion_codes: true,
      success_url: settings_billing_url,
      cancel_url: settings_billing_url
    })

    redirect_to session.url, allow_other_host: true, status: :see_other
  end

  def show
    client = Stripe::StripeClient.new(ENV["STRIPE_SECRET_KEY"])

    portal_session = client.v1.billing_portal.sessions.create(
      customer: Current.family.stripe_customer_id,
      return_url: settings_billing_url
    )
    redirect_to portal_session.url, allow_other_host: true, status: :see_other
  end
end
