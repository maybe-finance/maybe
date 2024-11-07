module Plaidable
  extend ActiveSupport::Concern

  class_methods do
    def plaid_provider
      Provider::Plaid.new unless Rails.application.config.app_mode.self_hosted?
    end
  end

  private
    def plaid_provider
      self.class.plaid_provider
    end
end
