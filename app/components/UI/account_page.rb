class UI::AccountPage < ApplicationComponent
  attr_reader :account, :chart_view, :chart_period

  def initialize(account:, chart_view: nil, chart_period: nil, active_tab: nil)
    @account = account
    @chart_view = chart_view
    @chart_period = chart_period
    @active_tab = active_tab
  end

  def title
    account.name
  end

  def subtitle
    return nil unless account.property?

    account.property.address
  end

  def active_tab
    tabs.find { |tab| tab == @active_tab&.to_sym } || tabs.first
  end

  def tabs
    case account.accountable_type
    when "Investment"
      [ :activity, :holdings ]
    when "Property", "Vehicle", "Loan"
      [ :activity, :overview ]
    else
      [ :activity ]
    end
  end

  def tab_partial_name(tab)
    case tab
    when :activity
      "accounts/show/activity"
    when :holdings, :overview
      # Accountable is responsible for implementing the partial in the correct folder
      "#{account.accountable_type.downcase.pluralize}/tabs/#{tab}"
    end
  end
end
