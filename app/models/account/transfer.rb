class Account::Transfer < ApplicationRecord
  has_many :entries, dependent: :nullify

  validate :net_zero_flows, if: :single_currency_transfer?
  validate :transaction_count, :from_different_accounts, :all_transactions_marked

  def date
    outflow_transaction&.date
  end

  def amount_money
    entries.first&.amount_money&.abs
  end

  def from_name
    outflow_transaction&.account&.name || I18n.t("account.transfer.from_fallback_name")
  end

  def to_name
    inflow_transaction&.account&.name || I18n.t("account.transfer.to_fallback_name")
  end

  def name
    I18n.t("account.transfer.name", from_account: from_name, to_account: to_name)
  end

  def inflow_transaction
    entries.find { |e| e.inflow? }
  end

  def outflow_transaction
    entries.find { |e| e.outflow? }
  end

  def destroy_and_remove_marks!
    transaction do
      entries.each do |e|
        e.update! marked_as_transfer: false
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
        marked_as_transfer: true,
        entryable: Account::Transaction.new

      inflow = to_account.entries.build \
        amount: amount.abs * -1,
        currency: currency,
        date: date,
        name: name,
        marked_as_transfer: true,
        entryable: Account::Transaction.new

      new entries: [ outflow, inflow ]
    end
  end

  private

    def single_currency_transfer?
      entries.map { |e| e.currency }.uniq.size == 1
    end

    def transaction_count
      unless entries.size == 2
        errors.add :entries, "must have exactly 2 entries"
      end
    end

    def from_different_accounts
      accounts = entries.map { |e| e.account_id }.uniq
      errors.add :entries, "must be from different accounts" if accounts.size < entries.size
    end

    def net_zero_flows
      unless entries.sum(&:amount).zero?
        errors.add :transactions, "must have an inflow and outflow that net to zero"
      end
    end

    def all_transactions_marked
      unless entries.all?(&:marked_as_transfer)
        errors.add :entries, "must be marked as transfer"
      end
    end
end
