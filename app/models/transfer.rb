class Transfer < ApplicationRecord
  belongs_to :inflow_transaction, class_name: "Account::Transaction"
  belongs_to :outflow_transaction, class_name: "Account::Transaction"

  enum :status, { pending: "pending", confirmed: "confirmed", rejected: "rejected" }

  validate :transfer_has_different_accounts
  validate :transfer_has_opposite_amounts
  validate :transfer_within_date_range
  validate :transfer_has_same_family
  validate :inflow_on_or_after_outflow

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
        inflow_transaction: Account::Transaction.new(
          entry: to_account.entries.build(
            amount: converted_amount.amount.abs * -1,
            currency: converted_amount.currency.iso_code,
            date: date,
            name: "Transfer from #{from_account.name}",
            entryable: Account::Transaction.new
          )
        ),
        outflow_transaction: Account::Transaction.new(
          entry: from_account.entries.build(
            amount: amount.abs,
            currency: from_account.currency,
            date: date,
            name: "Transfer to #{to_account.name}",
            entryable: Account::Transaction.new
          )
        ),
        status: "confirmed"
      )
    end

    def auto_match_for_account(account)
      matches = Account::Entry.select([
        "inflow_candidates.entryable_id as inflow_transaction_id",
        "outflow_candidates.entryable_id as outflow_transaction_id"
      ]).from("account_entries inflow_candidates")
        .joins("
          JOIN account_entries outflow_candidates ON (
            inflow_candidates.amount < 0 AND
            outflow_candidates.amount > 0 AND
            inflow_candidates.amount = -outflow_candidates.amount AND
            inflow_candidates.currency = outflow_candidates.currency AND
            inflow_candidates.account_id <> outflow_candidates.account_id AND
            inflow_candidates.date BETWEEN outflow_candidates.date - 4 AND outflow_candidates.date + 4 AND
            inflow_candidates.date >= outflow_candidates.date
          )
        ").joins("
          LEFT JOIN transfers existing_transfers ON (
            existing_transfers.inflow_transaction_id = inflow_candidates.entryable_id AND
            existing_transfers.outflow_transaction_id = outflow_candidates.entryable_id
          )
        ")
        .joins("JOIN accounts inflow_accounts ON inflow_accounts.id = inflow_candidates.account_id")
        .joins("JOIN accounts outflow_accounts ON outflow_accounts.id = outflow_candidates.account_id")
        .where("inflow_accounts.family_id = ? AND outflow_accounts.family_id = ?", account.family_id, account.family_id)
        .where("inflow_candidates.entryable_type = 'Account::Transaction' AND outflow_candidates.entryable_type = 'Account::Transaction'")
        .where(existing_transfers: { id: nil })

      Transfer.transaction do
        matches.each do |match|
          Transfer.create!(
            inflow_transaction_id: match.inflow_transaction_id,
            outflow_transaction_id: match.outflow_transaction_id,
          )
        end
      end
    end
  end

  def sync_account_later
    inflow_transaction.entry.sync_account_later
    outflow_transaction.entry.sync_account_later
  end

  def belongs_to_family?(family)
    family.transactions.include?(inflow_transaction)
  end

  def to_account
    inflow_transaction.entry.account
  end

  def from_account
    outflow_transaction.entry.account
  end

  def amount_abs
    inflow_transaction.entry.amount_money.abs
  end

  def name
    if payment?
      I18n.t("transfer.payment_name", to_account: to_account.name)
    else
      I18n.t("transfer.name", to_account: to_account.name)
    end
  end

  def payment?
    to_account.liability?
  end

  def categorizable?
    to_account.accountable_type == "Loan"
  end

  private
    def inflow_on_or_after_outflow
      return unless inflow_transaction.present? && outflow_transaction.present?
      errors.add(:base, :inflow_must_be_on_or_after_outflow) if inflow_transaction.entry.date < outflow_transaction.entry.date
    end

    def transfer_has_different_accounts
      return unless inflow_transaction.present? && outflow_transaction.present?
      errors.add(:base, :must_be_from_different_accounts) if inflow_transaction.entry.account == outflow_transaction.entry.account
    end

    def transfer_has_same_family
      return unless inflow_transaction.present? && outflow_transaction.present?
      errors.add(:base, :must_be_from_same_family) unless inflow_transaction.entry.account.family == outflow_transaction.entry.account.family
    end

    def transfer_has_opposite_amounts
      return unless inflow_transaction.present? && outflow_transaction.present?

      inflow_amount = inflow_transaction.entry.amount
      outflow_amount = outflow_transaction.entry.amount

      if inflow_transaction.entry.currency == outflow_transaction.entry.currency
        # For same currency, amounts must be exactly opposite
        errors.add(:base, :must_have_opposite_amounts) if inflow_amount + outflow_amount != 0
      else
        # For different currencies, just check the signs are opposite
        errors.add(:base, :must_have_opposite_amounts) unless inflow_amount.negative? && outflow_amount.positive?
      end
    end

    def transfer_within_date_range
      return unless inflow_transaction.present? && outflow_transaction.present?

      date_diff = (inflow_transaction.entry.date - outflow_transaction.entry.date).abs
      errors.add(:base, :must_be_within_date_range) if date_diff > 4
    end
end
