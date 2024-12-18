module Plaidable
  extend ActiveSupport::Concern

  class_methods do
    def plaid_provider
      Provider::Plaid.new if Rails.application.config.plaid
    end

    def plaid_eu_provider
      Provider::Plaid.new if Rails.application.config.plaid_eu
    end
  end

  private
    def plaid_provider
      self.class.plaid_provider
    end

    def plaid_eu_provider
      self.class.plaid_eu_provider
    end
end
