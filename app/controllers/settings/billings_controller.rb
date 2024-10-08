class Settings::BillingsController < SettingsController
  def subscribe
    if Current.family.stripe_customer_id.blank?
      customer = Stripe::Customer.create(
        email: Current.family.primary_user.email,
        metadata: { family_id: Current.family.id }
      )
      Current.family.update(stripe_customer_id: customer.id)
    end

    session = Stripe::Checkout::Session.create({
      customer: Current.family.stripe_customer_id,
      line_items: [ {
        price: ENV["STRIPE_PLAN_ID"],
        quantity: 1
      } ],
      mode: "subscription",
      success_url: settings_billing_url,
      cancel_url: settings_billing_url
    })

    redirect_to session.url, allow_other_host: true, status: :see_other
  end

  def portal
    portal_session = Stripe::BillingPortal::Session.create(
      customer: Current.family.stripe_customer_id,
      return_url: settings_billing_url
    )
    redirect_to portal_session.url, allow_other_host: true, status: :see_other
  end
end
