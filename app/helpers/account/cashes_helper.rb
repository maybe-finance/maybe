module Account::CashesHelper
  def brokerage_cash(account)
    currency = Money::Currency.new(account.currency)

    account.holdings.build \
      date: Date.current,
      qty: account.balance,
      price: 1,
      amount: account.balance,
      currency: account.currency,
      security: Security.new(ticker: currency.iso_code, name: currency.name)
  end
end
