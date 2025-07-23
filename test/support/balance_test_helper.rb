module BalanceTestHelper
  def create_balance(account:, date:, balance:, cash_balance: nil, **attributes)
    # If cash_balance is not provided, default to entire balance being cash
    cash_balance ||= balance

    # Calculate non-cash balance
    non_cash_balance = balance - cash_balance

    # Set default component values that will generate the desired end_balance
    # flows_factor should be 1 for assets, -1 for liabilities
    flows_factor = account.classification == "liability" ? -1 : 1

    defaults = {
      date: date,
      balance: balance,
      cash_balance: cash_balance,
      currency: account.currency,
      start_cash_balance: cash_balance,
      start_non_cash_balance: non_cash_balance,
      cash_inflows: 0,
      cash_outflows: 0,
      non_cash_inflows: 0,
      non_cash_outflows: 0,
      net_market_flows: 0,
      cash_adjustments: 0,
      non_cash_adjustments: 0,
      flows_factor: flows_factor
    }

    account.balances.create!(defaults.merge(attributes))
  end

  def create_balance_with_flows(account:, date:, start_balance:, end_balance:,
                                cash_portion: 1.0, cash_flow: 0, non_cash_flow: 0,
                                market_flow: 0, **attributes)
    # Calculate cash and non-cash portions
    start_cash = start_balance * cash_portion
    start_non_cash = start_balance * (1 - cash_portion)

    # Calculate adjustments needed to reach end_balance
    expected_end_cash = start_cash + cash_flow
    expected_end_non_cash = start_non_cash + non_cash_flow + market_flow
    expected_total = expected_end_cash + expected_end_non_cash

    # Calculate adjustments if end_balance doesn't match expected
    total_adjustment = end_balance - expected_total
    cash_adjustment = cash_portion * total_adjustment
    non_cash_adjustment = (1 - cash_portion) * total_adjustment

    # flows_factor should be 1 for assets, -1 for liabilities
    flows_factor = account.classification == "liability" ? -1 : 1

    defaults = {
      date: date,
      balance: end_balance,
      cash_balance: expected_end_cash + cash_adjustment,
      currency: account.currency,
      start_cash_balance: start_cash,
      start_non_cash_balance: start_non_cash,
      cash_inflows: cash_flow > 0 ? cash_flow : 0,
      cash_outflows: cash_flow < 0 ? -cash_flow : 0,
      non_cash_inflows: non_cash_flow > 0 ? non_cash_flow : 0,
      non_cash_outflows: non_cash_flow < 0 ? -non_cash_flow : 0,
      net_market_flows: market_flow,
      cash_adjustments: cash_adjustment,
      non_cash_adjustments: non_cash_adjustment,
      flows_factor: flows_factor
    }

    account.balances.create!(defaults.merge(attributes))
  end
end
