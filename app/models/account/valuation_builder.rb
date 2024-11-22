class Account::ValuationBuilder
  include ActiveModel::Model

  attr_accessor :date, :amount, :currency, :account_id

  def create
    valuation = Account::Entry.new(
      account_id: account_id,
      date: date,
      amount: amount,
      currency: currency,
      entryable: Account::Valuation.new
    )

    valuation.save
  end

  def update(entry)
    entry.update(
      date: date,
      amount: amount,
      currency: currency
    )

    entry.sync_account_later
  end
end
