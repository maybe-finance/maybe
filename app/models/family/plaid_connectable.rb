module Family::PlaidConnectable
  extend ActiveSupport::Concern

  included do
    has_many :plaid_items, dependent: :destroy
  end

  def create_plaid_item!(public_token:, item_name:, region:)
    provider = plaid_provider_for_region(region)

    public_token_response = provider.exchange_public_token(public_token)

    plaid_item = plaid_items.create!(
      name: item_name,
      plaid_id: public_token_response.item_id,
      access_token: public_token_response.access_token,
      plaid_region: region
    )

    plaid_item.sync_later

    plaid_item
  end

  def get_link_token(webhooks_url:, redirect_url:, accountable_type: nil, region: :us, access_token: nil)
    return nil unless plaid_us || plaid_eu

    provider = plaid_provider_for_region(region)

    provider.get_link_token(
      user_id: self.id,
      webhooks_url: webhooks_url,
      redirect_url: redirect_url,
      accountable_type: accountable_type,
      access_token: access_token
    ).link_token
  end

  private
    def plaid_us
      @plaid ||= Provider::Registry.get_provider(:plaid_us)
    end

    def plaid_eu
      @plaid_eu ||= Provider::Registry.get_provider(:plaid_eu)
    end

    def plaid_provider_for_region(region)
      region.to_sym == :eu ? plaid_eu : plaid_us
    end
end
