module Account::HoldingsHelper
  def brokerage_cash_holding(account)
    currency = Money::Currency.new(account.currency)
    amount = account.investment? ? account.investment.cash_balance : account.balance

    account.holdings.build \
      date: Date.current,
      qty: amount,
      price: 1,
      amount: amount,
      currency: currency.iso_code,
      security: Security.new(ticker: currency.iso_code, name: currency.name)
  end
end
