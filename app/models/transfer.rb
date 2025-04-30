class Transfer < ApplicationRecord
  belongs_to :inflow_transaction, class_name: "Transaction"
  belongs_to :outflow_transaction, class_name: "Transaction"

  enum :status, { pending: "pending", confirmed: "confirmed" }

  validates :inflow_transaction_id, uniqueness: true
  validates :outflow_transaction_id, uniqueness: true

  validate :transfer_has_different_accounts
  validate :transfer_has_opposite_amounts
  validate :transfer_within_date_range
  validate :transfer_has_same_family

  class << self
    def from_accounts(from_account:, to_account:, date:, amount:)
      # Attempt to convert the amount to the to_account's currency.
      # If the conversion fails, use the original amount.
      converted_amount = begin
        Money.new(amount.abs, from_account.currency).exchange_to(to_account.currency)
      rescue Money::ConversionError
        Money.new(amount.abs, from_account.currency)
      end

      new(
        inflow_transaction: Transaction.new(
          entry: to_account.entries.build(
            amount: converted_amount.amount.abs * -1,
            currency: converted_amount.currency.iso_code,
            date: date,
            name: "Transfer from #{from_account.name}",
          )
        ),
        outflow_transaction: Transaction.new(
          entry: from_account.entries.build(
            amount: amount.abs,
            currency: from_account.currency,
            date: date,
            name: "Transfer to #{to_account.name}",
          )
        ),
        status: "confirmed"
      )
    end
  end

  def reject!
    Transfer.transaction do
      RejectedTransfer.find_or_create_by!(inflow_transaction_id: inflow_transaction_id, outflow_transaction_id: outflow_transaction_id)
      destroy!
    end
  end

  def confirm!
    update!(status: "confirmed")
  end

  def sync_account_later
    inflow_transaction&.entry&.sync_account_later
    outflow_transaction&.entry&.sync_account_later
  end

  def belongs_to_family?(family)
    family.transactions.include?(inflow_transaction)
  end

  def to_account
    inflow_transaction&.entry&.account
  end

  def from_account
    outflow_transaction&.entry&.account
  end

  def amount_abs
    inflow_transaction&.entry&.amount_money&.abs
  end

  def name
    acc = to_account
    if payment?
      acc ? "Payment to #{acc.name}" : "Payment"
    else
      acc ? "Transfer to #{acc.name}" : "Transfer"
    end
  end

  def payment?
    to_account&.liability?
  end

  def categorizable?
    to_account&.accountable_type == "Loan"
  end

  private
    def transfer_has_different_accounts
      return unless inflow_transaction&.entry && outflow_transaction&.entry
      errors.add(:base, "Must be from different accounts") if to_account == from_account
    end

    def transfer_has_same_family
      return unless inflow_transaction&.entry && outflow_transaction&.entry
      errors.add(:base, "Must be from same family") unless to_account&.family == from_account&.family
    end

    def transfer_has_opposite_amounts
      return unless inflow_transaction&.entry && outflow_transaction&.entry

      inflow_entry = inflow_transaction.entry
      outflow_entry = outflow_transaction.entry

      inflow_amount = inflow_entry.amount
      outflow_amount = outflow_entry.amount

      if inflow_entry.currency == outflow_entry.currency
        # For same currency, amounts must be exactly opposite
        errors.add(:base, "Must have opposite amounts") if inflow_amount + outflow_amount != 0
      else
        # For different currencies, just check the signs are opposite
        errors.add(:base, "Must have opposite amounts") unless inflow_amount.negative? && outflow_amount.positive?
      end
    end

    def transfer_within_date_range
      return unless inflow_transaction&.entry && outflow_transaction&.entry

      date_diff = (inflow_transaction.entry.date - outflow_transaction.entry.date).abs
      errors.add(:base, "Must be within 4 days") if date_diff > 4
    end
end
