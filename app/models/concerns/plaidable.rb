module Plaidable
  extend ActiveSupport::Concern

  class_methods do
    def plaid_provider
      Provider::Plaid.new if Rails.application.config.plaid
    end
  end

  private
    def plaid_provider
      self.class.plaid_provider
    end
end
