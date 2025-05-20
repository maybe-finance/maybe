# Plaid Investment balances have a ton of edge cases.  This processor is responsible
# for deriving "brokerage cash" vs. "total value" based on Plaid's reported balances and holdings.
class PlaidAccount::InvestmentBalanceProcessor
  attr_reader :plaid_account

  def initialize(plaid_account)
    @plaid_account = plaid_account
  end

  def balance
    plaid_account.current_balance || plaid_account.available_balance
  end

  def cash_balance
    plaid_account.available_balance || 0
  end
end
