module Account::EntriesTestHelper
  def create_transfer(from:, to:, amount: 100)
    inflow = create_transaction(account: to, amount: amount.abs, marked_as_transfer: true)
    outflow = create_transaction(account: from, amount: -amount.abs, marked_as_transfer: true)

    Account::Transfer.create!(entries: [ inflow, outflow ])
  end

  def create_transaction(attributes = {})
    entry_attributes = attributes.except(:category, :tags, :merchant)
    transaction_attributes = attributes.slice(:category, :tags, :merchant)

    entry_defaults = {
      account: accounts(:depository),
      name: "Transaction",
      date: Date.current,
      currency: "USD",
      amount: 100,
      entryable: Account::Transaction.new(transaction_attributes)
    }

    Account::Entry.create! entry_defaults.merge(entry_attributes)
  end

  def create_valuation(attributes = {})
    entry_defaults = {
      account: accounts(:depository),
      name: "Valuation",
      date: 1.day.ago.to_date,
      currency: "USD",
      amount: 5000,
      entryable: Account::Valuation.new
    }

    Account::Entry.create! entry_defaults.merge(attributes)
  end

  def create_trade(security, account:, qty:, date:, price: nil)
    trade_price = price || Security::Price.find_by!(ticker: security.ticker, date: date).price

    trade = Account::Trade.new \
      qty: qty,
      security: security,
      price:    trade_price,
      currency: "USD"

    account.entries.create! \
      name: "Trade",
      date: date,
      amount: qty * trade_price,
      currency: "USD",
      entryable: trade
  end
end
