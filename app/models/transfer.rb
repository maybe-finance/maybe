class Transfer < ApplicationRecord
  has_many :transactions, dependent: :nullify

  validate :max_transaction_count, :from_different_accounts, :net_zero_flows

  private

    def max_transaction_count
      errors.add :transactions, "cannot have more than 2 transactions" if transactions.size > 2
    end

    def from_different_accounts
      accounts = transactions.map(&:account_id).uniq
      errors.add :transactions, "must be from different accounts" if accounts.size < transactions.size
    end

    def net_zero_flows
      # Transfer will be one-sided if external, which is okay
      return if transactions.size == 1

      errors.add :transactions, "must have an inflow and outflow that net to zero" if transactions.sum(&:amount) != 0
    end
end
