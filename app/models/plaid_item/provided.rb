module PlaidItem::Provided
  extend ActiveSupport::Concern

  def plaid_provider
    @plaid_provider ||= Provider::Registry.plaid_provider_for_region(self.plaid_region)
  end
end
