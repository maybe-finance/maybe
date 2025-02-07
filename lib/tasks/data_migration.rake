namespace :data_migration do
  desc "Migrate EU Plaid webhooks"
  # 2025-02-07: EU Plaid items need to be moved over to a new webhook URL so that we can
  # instantiate the correct Plaid client for verification based on which Plaid instance it comes from
  task eu_plaid_webhooks: :environment do
    provider = Provider::Plaid.new(Rails.application.config.plaid_eu, region: :eu)

    eu_items = PlaidItem.where(plaid_region: "eu")

    eu_items.find_each do |item|
      request = Plaid::ItemWebhookUpdateRequest.new(
        access_token: item.access_token,
        webhook: "https://app.maybefinance.com/webhooks/plaid_eu"
      )

      provider.client.item_webhook_update(request)

      puts "Updated webhook for Plaid item #{item.plaid_id}"
    rescue => error
      puts "Error updating webhook for Plaid item #{item.plaid_id}: #{error.message}"
    end
  end
end
