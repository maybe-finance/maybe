class Assistant::Function::GetBalanceSheet < Assistant::Function
  class << self
    def name
      "get_balance_sheet"
    end

    def description
      "Use this to get point-in-time snapshots of the user's aggregate financial position, including assets, liabilities, net worth, and more."
    end
  end

  def call(params = {})
    balance_sheet = BalanceSheet.new(family)
    balance_sheet.to_ai_readable_hash
  end

  private 
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
