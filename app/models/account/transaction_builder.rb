class Account::TransactionBuilder
  include ActiveModel::Model

  TYPES = %w[ income expense interest transfer_in transfer_out ].freeze

  attr_accessor :type, :amount, :date, :account, :transfer_account_id

  validates :type, :amount, :date, presence: true
  validates :type, inclusion: { in: TYPES }

  def save
    if valid?
      create_entry
    end
  end

  private

    def create_entry
      case type
      when "transfer_in"
        create_transfer_in
      when "transfer_out"
        create_transfer_out
      else
        create_transaction
      end
    end

    def create_transfer_in
      from_account_id = transfer_account_id
      to_account_id = account.id

      if from_account_id && to_account_id
        create_transfer(from_account_id, to_account_id)
      else
        create_unconfirmed_transfer
      end
    end

    def create_transfer_out
      to_account_id = transfer_account_id
      from_account_id = account.id

      if from_account_id && to_account_id
        create_transfer(from_account_id, to_account_id)
      else
        create_unconfirmed_transfer
      end
    end

    def create_transfer(from_account_id, to_account_id)
      outflow = Account::Entry.new \
        account_id: from_account_id,
        amount: signed_amount.abs,
        currency: account.currency,
        date: date,
        marked_as_transfer: true,
        entryable: Account::Transaction.new

      inflow = Account::Entry.new \
        account_id: to_account_id,
        amount: signed_amount.abs * -1,
        currency: account.currency,
        date: date,
        marked_as_transfer: true,
        entryable: Account::Transaction.new

      Account::Transfer.create! entries: [ outflow, inflow ]

      inflow
    end

    def create_unconfirmed_transfer
      create_transaction(marked_as_transfer: true)
    end

    def create_transaction(marked_as_transfer: false)
      account.entries.create! \
        date: date,
        amount: signed_amount,
        currency: account.currency,
        marked_as_transfer: marked_as_transfer,
        entryable: Account::Transaction.new
    end

    def signed_amount
      type == "expense" ? amount.to_d : amount.to_d * -1
    end
end
