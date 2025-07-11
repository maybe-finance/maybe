module EntriesTestHelper
  def create_transaction(attributes = {})
    entry_attributes = attributes.except(:category, :tags, :merchant, :kind)
    transaction_attributes = attributes.slice(:category, :tags, :merchant, :kind)

    entry_defaults = {
      account: accounts(:depository),
      name: "Transaction",
      date: Date.current,
      currency: "USD",
      amount: 100,
      entryable: Transaction.new(transaction_attributes)
    }

    Entry.create! entry_defaults.merge(entry_attributes)
  end

  def create_valuation(attributes = {})
    account = attributes[:account] || accounts(:depository)
    amount = attributes[:amount] || 5000
    cash_balance = account.accountable_type == "Depository" ? amount : 0
    
    entry_defaults = {
      account: account,
      name: "Valuation",
      date: 1.day.ago.to_date,
      currency: "USD",
      amount: amount,
      entryable: Valuation.new(kind: "reconciliation", balance: amount, cash_balance: cash_balance)
    }

    Entry.create! entry_defaults.merge(attributes)
  end

  def create_trade(security, account:, qty:, date:, price: nil, currency: "USD")
    trade_price = price || Security::Price.find_by!(security: security, date: date).price

    trade = Trade.new \
      qty: qty,
      security: security,
      price: trade_price,
      currency: currency

    account.entries.create! \
      name: "Trade",
      date: date,
      amount: qty * trade_price,
      currency: currency,
      entryable: trade
  end
end
