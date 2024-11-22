class Account::ValuationBuilder
  include ActiveModel::Model

  attr_accessor :date, :amount, :currency, :account_id

  def create
    entry = Account::Entry.new(
      account_id: account_id,
      date: date,
      amount: amount,
      currency: currency,
      entryable: Account::Valuation.new
    )

    saved = entry.save

    entry.sync_account_later if saved

    [ saved, entry ]
  end

  def update(entry)
    updated = entry.update(
      date: date,
      amount: amount,
      currency: currency
    )

    entry.sync_account_later if updated

    updated
  end
end
