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
    entry_attributes = attributes.except(:kind)
    valuation_attributes = attributes.slice(:kind)

    account = attributes[:account] || accounts(:depository)
    amount = attributes[:amount] || 5000

    entry_defaults = {
      account: account,
      name: "Valuation",
      date: 1.day.ago.to_date,
      currency: "USD",
      amount: amount,
      entryable: Valuation.new({ kind: "reconciliation" }.merge(valuation_attributes))
    }

    Entry.create! entry_defaults.merge(entry_attributes)
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

  def create_transfer(from_account:, to_account:, amount:, date: Date.current, currency: "USD")
    outflow_transaction = Transaction.create!(kind: "funds_movement")
    inflow_transaction = Transaction.create!(kind: "funds_movement")

    transfer = Transfer.create!(
      outflow_transaction: outflow_transaction,
      inflow_transaction: inflow_transaction
    )

    # Create entries for both accounts
    from_account.entries.create!(
      name: "Transfer to #{to_account.name}",
      date: date,
      amount: -amount.abs,
      currency: currency,
      entryable: outflow_transaction
    )

    to_account.entries.create!(
      name: "Transfer from #{from_account.name}",
      date: date,
      amount: amount.abs,
      currency: currency,
      entryable: inflow_transaction
    )

    transfer
  end
end
