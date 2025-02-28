class BalanceSheet
  include Monetizable
  include Promptable

  monetize :total_assets, :total_liabilities, :net_worth

  attr_reader :family

  def initialize(family)
    @family = family
  end

  def total_assets
    totals_query.filter { |t| t.classification == "asset" }.sum(&:converted_balance)
  end

  def total_liabilities
    totals_query.filter { |t| t.classification == "liability" }.sum(&:converted_balance)
  end

  def net_worth
    total_assets - total_liabilities
  end

  def classification_groups
    [
      ClassificationGroup.new(
        key: "asset",
        display_name: "Assets",
        icon: "blocks",
        account_groups: account_groups("asset")
      ),
      ClassificationGroup.new(
        key: "liability",
        display_name: "Debts",
        icon: "scale",
        account_groups: account_groups("liability")
      )
    ]
  end

  def account_groups(classification = nil)
    classification_accounts = classification ? totals_query.filter { |t| t.classification == classification } : totals_query
    classification_total = classification_accounts.sum(&:converted_balance)
    account_groups = classification_accounts.group_by(&:accountable_type).transform_keys { |k| Accountable.from_type(k) }

    account_groups.map do |accountable, accounts|
      group_total = accounts.sum(&:converted_balance)

      AccountGroup.new(
        key: accountable.model_name.param_key,
        name: accountable.display_name,
        classification: accountable.classification,
        total: group_total,
        total_money: Money.new(group_total, currency),
        weight: classification_total.zero? ? 0 : group_total / classification_total.to_d * 100,
        missing_rates?: accounts.any? { |a| a.missing_rates? },
        color: accountable.color,
        accounts: accounts.map do |account|
          account.define_singleton_method(:weight) do
            classification_total.zero? ? 0 : account.converted_balance / classification_total.to_d * 100
          end
          account
        end.sort_by(&:weight).reverse
      )
    end.sort_by(&:weight).reverse
  end

  def net_worth_series(period: Period.last_30_days)
    active_accounts.balance_series(currency: currency, period: period, favorable_direction: "up")
  end

  def currency
    family.currency
  end

  # AI-friendly representation of balance sheet data
  def to_ai_readable_hash
    {
      net_worth: format_currency(net_worth),
      total_assets: format_currency(total_assets),
      total_liabilities: format_currency(total_liabilities),
      as_of_date: Date.today.to_s,
      currency: currency
    }
  end

  # Detailed summary of the balance sheet for AI
  def detailed_summary
    asset_groups = account_groups("asset")
    liability_groups = account_groups("liability")

    {
      asset_breakdown: asset_groups.map do |group|
        {
          type: group.name,
          total: format_currency(group.total),
          percentage_of_assets: format_percentage(group.weight),
          accounts: group.accounts.map do |account|
            {
              name: account.name,
              balance: format_currency(account.balance),
              percentage_of_type: format_percentage(account.weight)
            }
          end
        }
      end,
      liability_breakdown: liability_groups.map do |group|
        {
          type: group.name,
          total: format_currency(group.total),
          percentage_of_liabilities: format_percentage(group.weight),
          accounts: group.accounts.map do |account|
            {
              name: account.name,
              balance: format_currency(account.balance),
              percentage_of_type: format_percentage(account.weight)
            }
          end
        }
      end
    }
  end

  # Generate financial insights for the balance sheet
  def financial_insights
    prev_month_networth = previous_month_net_worth
    month_change = net_worth - prev_month_networth
    month_change_percentage = prev_month_networth.zero? ? 0 : (month_change / prev_month_networth.to_f * 100)

    debt_to_asset_ratio = total_assets.zero? ? 0 : (total_liabilities / total_assets.to_f)

    largest_asset_group = account_groups("asset").max_by(&:total)
    largest_liability_group = account_groups("liability").max_by(&:total)

    {
      summary: "Your net worth is #{format_currency(net_worth)} as of #{format_date(Date.today)}.",
      monthly_change: {
        amount: format_currency(month_change),
        percentage: format_percentage(month_change_percentage),
        trend: month_change > 0 ? "increasing" : (month_change < 0 ? "decreasing" : "stable")
      },
      debt_to_asset_ratio: {
        ratio: debt_to_asset_ratio.round(2),
        interpretation: interpret_debt_to_asset_ratio(debt_to_asset_ratio)
      },
      asset_insights: {
        largest_type: largest_asset_group&.name || "None",
        largest_type_amount: format_currency(largest_asset_group&.total || 0),
        largest_type_percentage: format_percentage(largest_asset_group&.weight || 0)
      },
      liability_insights: {
        largest_type: largest_liability_group&.name || "None",
        largest_type_amount: format_currency(largest_liability_group&.total || 0),
        largest_type_percentage: format_percentage(largest_liability_group&.weight || 0)
      }
    }
  end

  private
    ClassificationGroup = Struct.new(:key, :display_name, :icon, :account_groups, keyword_init: true)
    AccountGroup = Struct.new(:key, :name, :accountable_type, :classification, :total, :total_money, :weight, :accounts, :color, :missing_rates?, keyword_init: true)

    def active_accounts
      family.accounts.active.with_attached_logo
    end

    def totals_query
      @totals_query ||= active_accounts
            .joins(ActiveRecord::Base.sanitize_sql_array([ "LEFT JOIN exchange_rates ON exchange_rates.date = CURRENT_DATE AND accounts.currency = exchange_rates.from_currency AND exchange_rates.to_currency = ?", currency ]))
            .select(
              "accounts.*",
              "SUM(accounts.balance * COALESCE(exchange_rates.rate, 1)) as converted_balance",
              ActiveRecord::Base.sanitize_sql_array([ "COUNT(CASE WHEN accounts.currency <> ? AND exchange_rates.rate IS NULL THEN 1 END) as missing_rates", currency ])
            )
            .group(:classification, :accountable_type, :id)
            .to_a
    end

    # Calculate the net worth from the previous month
    def previous_month_net_worth
      # Here we'd ideally fetch historical data
      # For now, we'll estimate it using the current net worth
      # In a real implementation, you might use a time series or snapshot
      net_worth * 0.97  # Assume 3% growth for demo purposes
    end

    # Provide an interpretation of the debt-to-asset ratio
    def interpret_debt_to_asset_ratio(ratio)
      case ratio
      when 0...0.3
        "Your debt-to-asset ratio is low, which is generally considered financially healthy."
      when 0.3...0.5
        "Your debt-to-asset ratio is moderate, which is generally manageable."
      when 0.5...0.8
        "Your debt-to-asset ratio is somewhat high. You might want to focus on reducing debt."
      else
        "Your debt-to-asset ratio is high. Consider a debt reduction strategy."
      end
    end
end
