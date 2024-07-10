module Account::EntriesTestHelper
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
end
