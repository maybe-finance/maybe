class Balance::BaseCalculator
  attr_reader :account

  def initialize(account)
    @account = account
  end

  def calculate
    raise NotImplementedError, "Subclasses must implement this method"
  end

  private
    def sync_cache
      @sync_cache ||= Balance::SyncCache.new(account)
    end

    def holdings_value_for_date(date)
      @holdings_value_for_date ||= {}
      @holdings_value_for_date[date] ||= sync_cache.get_holdings(date).sum(&:amount)
    end

    def derive_cash_balance_on_date_from_total(total_balance:, date:)
      if account.balance_type == :investment
        total_balance - holdings_value_for_date(date)
      elsif account.balance_type == :cash
        total_balance
      else
        0
      end
    end

    def cash_adjustments_for_date(start_cash, end_cash, net_cash_flows)
      return 0 unless account.balance_type != :non_cash

      end_cash - start_cash - net_cash_flows
    end

    def non_cash_adjustments_for_date(start_non_cash, end_non_cash, non_cash_flows)
      return 0 unless account.balance_type == :non_cash

      end_non_cash - start_non_cash - non_cash_flows
    end

    # If holdings value goes from $100 -> $200 (change_holdings_value is $100)
    # And non-cash flows (i.e. "buys") for day are +$50 (net_buy_sell_value is $50)
    # That means value increased by $100, where $50 of that is due to the change in holdings value, and $50 is due to the buy/sell
    def market_value_change_on_date(date, flows)
      return 0 unless account.balance_type == :investment

      start_of_day_holdings_value = holdings_value_for_date(date.prev_day)
      end_of_day_holdings_value = holdings_value_for_date(date)

      change_holdings_value = end_of_day_holdings_value - start_of_day_holdings_value
      net_buy_sell_value = flows[:non_cash_inflows] - flows[:non_cash_outflows]

      change_holdings_value - net_buy_sell_value
    end

    def flows_for_date(date)
      entries = sync_cache.get_entries(date)

      cash_inflows = 0
      cash_outflows = 0
      non_cash_inflows = 0
      non_cash_outflows = 0

      txn_inflow_sum = entries.select { |e| e.amount < 0 && e.transaction? }.sum(&:amount)
      txn_outflow_sum = entries.select { |e| e.amount >= 0 && e.transaction? }.sum(&:amount)

      trade_cash_inflow_sum = entries.select { |e| e.amount < 0 && e.trade? }.sum(&:amount)
      trade_cash_outflow_sum = entries.select { |e| e.amount >= 0 && e.trade? }.sum(&:amount)

      if account.balance_type == :non_cash && account.accountable_type == "Loan"
        non_cash_inflows = txn_inflow_sum.abs
        non_cash_outflows = txn_outflow_sum
      elsif account.balance_type != :non_cash
        cash_inflows = txn_inflow_sum.abs + trade_cash_inflow_sum.abs
        cash_outflows = txn_outflow_sum + trade_cash_outflow_sum

        # Trades are inverse (a "buy" is outflow of cash, but "inflow" of non-cash, aka "holdings")
        non_cash_outflows = trade_cash_inflow_sum.abs
        non_cash_inflows = trade_cash_outflow_sum
      end

      {
        cash_inflows: cash_inflows,
        cash_outflows: cash_outflows,
        non_cash_inflows: non_cash_inflows,
        non_cash_outflows: non_cash_outflows
      }
    end

    def derive_cash_balance(cash_balance, date)
      entries = sync_cache.get_entries(date)

      if account.balance_type == :non_cash
        0
      else
        cash_balance + signed_entry_flows(entries)
      end
    end

    def derive_non_cash_balance(non_cash_balance, date, direction: :forward)
      entries = sync_cache.get_entries(date)
      # Loans are a special case (loan payment reducing principal, which is non-cash)
      if account.balance_type == :non_cash && account.accountable_type == "Loan"
        non_cash_balance + signed_entry_flows(entries)
      elsif account.balance_type == :investment
        # For reverse calculations, we need the previous day's holdings
        target_date = direction == :forward ? date : date.prev_day
        holdings_value_for_date(target_date)
      else
        non_cash_balance
      end
    end

    def signed_entry_flows(entries)
      raise NotImplementedError, "Directional calculators must implement this method"
    end

    def build_balance(date:, **args)
      Balance.new(
        account_id: account.id,
        currency: account.currency,
        date: date,
        balance: args[:balance],
        cash_balance: args[:cash_balance],
        start_cash_balance: args[:start_cash_balance] || 0,
        start_non_cash_balance: args[:start_non_cash_balance] || 0,
        cash_inflows: args[:cash_inflows] || 0,
        cash_outflows: args[:cash_outflows] || 0,
        non_cash_inflows: args[:non_cash_inflows] || 0,
        non_cash_outflows: args[:non_cash_outflows] || 0,
        cash_adjustments: args[:cash_adjustments] || 0,
        non_cash_adjustments: args[:non_cash_adjustments] || 0,
        net_market_flows: args[:net_market_flows] || 0,
        flows_factor: account.classification == "asset" ? 1 : -1
      )
    end
end
