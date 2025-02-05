module Account::HoldingsHelper
  def brokerage_cash_holding(account)
    currency = Money::Currency.new(account.currency)

    account.holdings.build \
      date: Date.current,
      qty: account.cash_balance,
      price: 1,
      amount: account.cash_balance,
      currency: currency.iso_code,
      security: Security.new(ticker: currency.iso_code, name: currency.name)
  end
end
