class Account::Transfer < ApplicationRecord
  has_many :transactions, dependent: :nullify

  validate :net_zero_flows, if: :single_currency_transfer?
  validate :transaction_count, :from_different_accounts, :all_transactions_marked

  def inflow_transaction
    transactions.find { |t| t.inflow? }
  end

  def outflow_transaction
    transactions.find { |t| t.outflow? }
  end

  def destroy_and_remove_marks!
    transaction do
      transactions.each do |t|
        t.update! marked_as_transfer: false
      end

      destroy!
    end
  end

  class << self
    def build_from_accounts(from_account, to_account, date:, amount:, currency:, name:)
      outflow = from_account.entries.build \
        amount: amount.abs,
        currency: currency,
        date: date,
        name: name,
        entryable: Account::Transaction.new(marked_as_transfer: true)

      inflow = to_account.entries.build \
        amount: -amount.abs,
        currency: currency,
        date: date,
        name: name,
        entryable: Account::Transaction.new(marked_as_transfer: true)

      new transactions: [ outflow.account_transaction, inflow.account_transaction ]
    end
  end

  private

    def single_currency_transfer?
      transactions.map(&:currency).uniq.size == 1
    end

    def transaction_count
      unless transactions.size == 2
        errors.add :transactions, "must have exactly 2 transactions"
      end
    end

    def from_different_accounts
      accounts = transactions.map { |transaction| transaction.entry.account_id }.uniq
      errors.add :transactions, "must be from different accounts" if accounts.size < transactions.size
    end

    def net_zero_flows
      unless transactions.sum(&:amount).zero?
        errors.add :transactions, "must have an inflow and outflow that net to zero"
      end
    end

    def all_transactions_marked
      unless transactions.all?(&:marked_as_transfer)
        errors.add :transactions, "must be marked as transfer"
      end
    end
end
