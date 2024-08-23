class Account::TransactionBuilder
  include ActiveModel::Model

  TYPES = %w[income expense interest transfer_in transfer_out].freeze

  attr_accessor :type, :amount, :date, :account, :transfer_account_id

  validates :type, :amount, :date, presence: true
  validates :type, inclusion: { in: TYPES }

  def save
    if valid?
      transfer? ? create_transfer : create_transaction
    end
  end

  private

    def transfer?
      %w[transfer_in transfer_out].include?(type)
    end

    def create_transfer
      return create_unlinked_transfer(account.id, signed_amount) unless transfer_account_id

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
        amount: amount,
        currency: account.currency,
        date: date,
        marked_as_transfer: marked_as_transfer,
        entryable: Account::Transaction.new
    end

    def signed_amount
      case type
      when "expense", "transfer_out"
        amount.to_d
      else
        amount.to_d * -1
      end
    end
end
