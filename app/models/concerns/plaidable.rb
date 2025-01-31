module Plaidable
  extend ActiveSupport::Concern

  class_methods do
    def plaid_provider
      Provider::Plaid.new if Rails.application.config.plaid
    end

    def plaid_eu_provider
      Provider::Plaid.new if Rails.application.config.plaid_eu
    end

    def plaid_provider_for(plaid_item)
      return nil unless plaid_item
      plaid_item.eu? ? plaid_eu_provider : plaid_provider
    end
  end

  private
    def plaid_provider_for(plaid_item)
      self.class.plaid_provider_for(plaid_item)
    end
end
