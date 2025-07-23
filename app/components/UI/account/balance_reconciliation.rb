class UI::Account::BalanceReconciliation < ApplicationComponent
  attr_reader :balance, :account

  def initialize(balance:, account:)
    @balance = balance
    @account = account
  end

  def reconciliation_items
    case account.accountable_type
    when "Depository", "OtherAsset", "OtherLiability"
      default_items
    when "CreditCard"
      credit_card_items
    when "Investment"
      investment_items
    when "Loan"
      loan_items
    when "Property", "Vehicle"
      asset_items
    when "Crypto"
      crypto_items
    else
      default_items
    end
  end

  private

    def default_items
      items = [
        { label: "Start balance", value: balance.start_balance_money, tooltip: "The account balance at the beginning of this day", style: :start },
        { label: "Net cash flow", value: net_cash_flow, tooltip: "Net change in balance from all transactions during the day", style: :flow }
      ]

      if has_adjustments?
        items << { label: "End balance", value: end_balance_before_adjustments, tooltip: "The calculated balance after all transactions", style: :subtotal }
        items << { label: "Adjustments", value: total_adjustments, tooltip: "Manual reconciliations or other adjustments", style: :adjustment }
      end

      items << { label: "Final balance", value: balance.end_balance_money, tooltip: "The final account balance for the day", style: :final }
      items
    end

    def credit_card_items
      items = [
        { label: "Start balance", value: balance.start_balance_money, tooltip: "The balance owed at the beginning of this day", style: :start },
        { label: "Charges", value: balance.cash_outflows_money, tooltip: "New charges made during the day", style: :flow },
        { label: "Payments", value: balance.cash_inflows_money * -1, tooltip: "Payments made to the card during the day", style: :flow }
      ]

      if has_adjustments?
        items << { label: "End balance", value: end_balance_before_adjustments, tooltip: "The calculated balance after all transactions", style: :subtotal }
        items << { label: "Adjustments", value: total_adjustments, tooltip: "Manual reconciliations or other adjustments", style: :adjustment }
      end

      items << { label: "Final balance", value: balance.end_balance_money, tooltip: "The final balance owed for the day", style: :final }
      items
    end

    def investment_items
      items = [
        { label: "Start balance", value: balance.start_balance_money, tooltip: "The total portfolio value at the beginning of this day", style: :start }
      ]

      # Change in brokerage cash (includes deposits, withdrawals, and cash from trades)
      items << { label: "Change in brokerage cash", value: net_cash_flow, tooltip: "Net change in cash from deposits, withdrawals, and trades", style: :flow }

      # Change in holdings from trading activity
      items << { label: "Change in holdings (buys/sells)", value: net_non_cash_flow, tooltip: "Impact on holdings from buying and selling securities", style: :flow }

      # Market price changes
      items << { label: "Change in holdings (market price activity)", value: balance.net_market_flows_money, tooltip: "Change in holdings value from market price movements", style: :flow }

      if has_adjustments?
        items << { label: "End balance", value: end_balance_before_adjustments, tooltip: "The calculated balance after all activity", style: :subtotal }
        items << { label: "Adjustments", value: total_adjustments, tooltip: "Manual reconciliations or other adjustments", style: :adjustment }
      end

      items << { label: "Final balance", value: balance.end_balance_money, tooltip: "The final portfolio value for the day", style: :final }
      items
    end

    def loan_items
      items = [
        { label: "Start principal", value: balance.start_balance_money, tooltip: "The principal balance at the beginning of this day", style: :start },
        { label: "Net principal change", value: net_non_cash_flow, tooltip: "Principal payments and new borrowing during the day", style: :flow }
      ]

      if has_adjustments?
        items << { label: "End principal", value: end_balance_before_adjustments, tooltip: "The calculated principal after all transactions", style: :subtotal }
        items << { label: "Adjustments", value: balance.non_cash_adjustments_money, tooltip: "Manual reconciliations or other adjustments", style: :adjustment }
      end

      items << { label: "Final principal", value: balance.end_balance_money, tooltip: "The final principal balance for the day", style: :final }
      items
    end

    def asset_items # Property/Vehicle
      items = [
        { label: "Start value", value: balance.start_balance_money, tooltip: "The asset value at the beginning of this day", style: :start },
        { label: "Net value change", value: net_total_flow, tooltip: "All value changes including improvements and depreciation", style: :flow }
      ]

      if has_adjustments?
        items << { label: "End value", value: end_balance_before_adjustments, tooltip: "The calculated value after all changes", style: :subtotal }
        items << { label: "Adjustments", value: total_adjustments, tooltip: "Manual value adjustments or appraisals", style: :adjustment }
      end

      items << { label: "Final value", value: balance.end_balance_money, tooltip: "The final asset value for the day", style: :final }
      items
    end

    def crypto_items
      items = [
        { label: "Start balance", value: balance.start_balance_money, tooltip: "The crypto holdings value at the beginning of this day", style: :start }
      ]

      items << { label: "Buys", value: balance.cash_outflows_money * -1, tooltip: "Crypto purchases during the day", style: :flow } if balance.cash_outflows != 0
      items << { label: "Sells", value: balance.cash_inflows_money, tooltip: "Crypto sales during the day", style: :flow } if balance.cash_inflows != 0
      items << { label: "Market changes", value: balance.net_market_flows_money, tooltip: "Value changes from market price movements", style: :flow } if balance.net_market_flows != 0

      if has_adjustments?
        items << { label: "End balance", value: end_balance_before_adjustments, tooltip: "The calculated balance after all activity", style: :subtotal }
        items << { label: "Adjustments", value: total_adjustments, tooltip: "Manual reconciliations or other adjustments", style: :adjustment }
      end

      items << { label: "Final balance", value: balance.end_balance_money, tooltip: "The final crypto holdings value for the day", style: :final }
      items
    end

    def net_cash_flow
      balance.cash_inflows_money - balance.cash_outflows_money
    end

    def net_non_cash_flow
      balance.non_cash_inflows_money - balance.non_cash_outflows_money
    end

    def net_total_flow
      net_cash_flow + net_non_cash_flow + balance.net_market_flows_money
    end

    def total_adjustments
      balance.cash_adjustments_money + balance.non_cash_adjustments_money
    end

    def has_adjustments?
      balance.cash_adjustments != 0 || balance.non_cash_adjustments != 0
    end

    def end_balance_before_adjustments
      balance.end_balance_money - total_adjustments
    end
end
