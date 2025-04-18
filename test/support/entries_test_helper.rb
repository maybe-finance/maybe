module EntriesTestHelper
  def create_transaction(attributes = {})
    entry_attributes = attributes.except(:category, :tags, :merchant)
    transaction_attributes = attributes.slice(:category, :tags, :merchant)

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
    entry_defaults = {
      account: accounts(:depository),
      name: "Valuation",
      date: 1.day.ago.to_date,
      currency: "USD",
      amount: 5000,
      entryable: Valuation.new
    }

    Entry.create! entry_defaults.merge(attributes)
  end

  def create_trade(security, account:, qty:, date:, price: nil)
    trade_price = price || Security::Price.find_by!(security: security, date: date).price

    trade = Trade.new \
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
