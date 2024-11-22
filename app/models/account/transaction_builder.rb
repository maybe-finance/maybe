class Account::TransactionBuilder
  include ActiveModel::Model

  attr_accessor :account_id, :name, :date, :amount, :currency, :excluded, :nature,
                :notes, :marked_as_transfer, :entryable_attributes

  def create
    entry = Account::Entry.new(
      account_id: account_id,
      name: name,
      date: date,
      amount: signed_amount,
      currency: currency,
      entryable: Account::Transaction.new(
        category_id: category_id,
      )
    )

    saved = entry.save

    entry.sync_account_later if saved

    [ saved, entry ]
  end

  def update(entry)
    prev_date = entry.date
    prev_amount = entry.amount
    prev_currency = entry.currency

    attributes = {
      name: name,
      date: date,
      amount: signed_amount,
      currency: currency,
      notes: notes,
      excluded: excluded,
      entryable_type: "Account::Transaction",
      entryable_attributes: entryable_attributes || {}
    }.compact

    updated = entry.update(attributes)

    if updated
      if prev_date != date || prev_amount != amount || prev_currency != currency
        entry.sync_account_later
      end
    end

    updated
  end

  private

    def signed_amount
      if nature == "inflow"
        amount.to_d * -1
      else
        amount
      end
    end

    def transfer?
      %w[transfer_in transfer_out].include?(type)
    end

    def create_transfer
      return create_unlinked_transfer(account.id, signed_amount) if transfer_account_id.blank?

      from_account_id = type == "transfer_in" ? transfer_account_id : account.id
      to_account_id = type == "transfer_in" ? account.id : transfer_account_id

      outflow = create_unlinked_transfer(from_account_id, signed_amount.abs)
      inflow = create_unlinked_transfer(to_account_id, signed_amount.abs * -1)

      Account::Transfer.create! entries: [ outflow, inflow ]

      inflow
    end

    def create_unlinked_transfer(account_id, amount)
      build_entry(account_id, amount, marked_as_transfer: true).tap(&:save!)
    end

    def create_transaction
      build_entry(account.id, signed_amount).tap(&:save!)
    end

    def build_entry(account_id, amount, marked_as_transfer: false)
      Account::Entry.new \
        account_id: account_id,
        name: marked_as_transfer ? (amount < 0 ? "Deposit" : "Withdrawal") : "Interest",
        amount: amount,
        currency: currency,
        date: date,
        marked_as_transfer: marked_as_transfer,
        entryable: Account::Transaction.new
    end
end
