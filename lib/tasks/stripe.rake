namespace :stripe do
  desc "Sync legacy Stripe subscriptions"
  task sync_legacy_subscriptions: :environment do
    cli = Stripe::StripeClient.new(ENV["STRIPE_SECRET_KEY"])

    subs = cli.v1.subscriptions.list

    subs.auto_paging_each do |sub|
      details = sub.items.data.first

      family = Family.find_by(stripe_customer_id: sub.customer)

      if family.nil?
        puts "Family not found for Stripe customer ID: #{sub.customer}, skipping"
        next
      end

      family.subscription.update!(
        stripe_id: sub.id,
        status: sub.status,
        interval: details.plan.interval,
        amount: details.plan.amount / 100.0,
        currency: details.plan.currency.upcase,
        current_period_ends_at: Time.at(details.current_period_end)
      )
    end
  end
end
