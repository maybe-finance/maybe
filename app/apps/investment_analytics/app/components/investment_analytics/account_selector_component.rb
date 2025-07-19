# app/apps/investment_analytics/app/components/investment_analytics/account_selector_component.rb

module InvestmentAnalytics
  class AccountSelectorComponent < ViewComponent::Base
    def initialize(accounts:, selected_account:)
      @accounts = accounts
      @selected_account = selected_account
    end

    def render?
      @accounts.any?
    end

    private

    attr_reader :accounts, :selected_account
  end
end
