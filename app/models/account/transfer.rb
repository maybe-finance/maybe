class Account::Transfer < ApplicationRecord
  has_many :entries, dependent: :destroy

  validate :net_zero_flows, if: :single_currency_transfer?
  validate :transaction_count, :from_different_accounts, :all_transactions_marked

  def date
    outflow_transaction&.date
  end

  def amount_money
    entries.first&.amount_money&.abs || Money.new(0)
  end

  def from_name
    from_account&.name || I18n.t("account/transfer.from_fallback_name")
  end

  def to_name
    to_account&.name || I18n.t("account/transfer.to_fallback_name")
  end

  def name
    I18n.t("account/transfer.name", from_account: from_name, to_account: to_name)
  end

  def from_account
    outflow_transaction&.account
  end

  def to_account
    inflow_transaction&.account
  end

  def inflow_transaction
    entries.find { |e| e.amount.negative? }
  end

  def outflow_transaction
    entries.find { |e| e.amount.positive? }
  end

  def update_entries!(params)
    transaction do
      entries.each do |entry|
        entry.update!(params)
      end
    end
  end

  def sync_account_later
    entries.each(&:sync_account_later)
  end

  class << self
    def build_from_accounts(from_account, to_account, date:, amount:)
      outflow = from_account.entries.build \
        amount: amount.abs,
        currency: from_account.currency,
        date: date,
        name: "Transfer to #{to_account.name}",
        entryable: Account::Transaction.new(
          category: from_account.family.default_transfer_category
        )

      # Attempt to convert the amount to the to_account's currency. If the conversion fails,
      # use the original amount.
      converted_amount = begin
        Money.new(amount.abs, from_account.currency).exchange_to(to_account.currency)
      rescue Money::ConversionError
        Money.new(amount.abs, from_account.currency)
      end

      inflow = to_account.entries.build \
        amount: converted_amount.amount * -1,
        currency: converted_amount.currency.iso_code,
        date: date,
        name: "Transfer from #{from_account.name}",
        entryable: Account::Transaction.new(
          category: to_account.family.default_transfer_category
        )

      new entries: [ outflow, inflow ]
    end
  end

  private

    def single_currency_transfer?
      entries.map { |e| e.currency }.uniq.size == 1
    end

    def transaction_count
      unless entries.size == 2
        errors.add :entries, :must_have_exactly_2_entries
      end
    end

    def from_different_accounts
      accounts = entries.map { |e| e.account_id }.uniq
      errors.add :entries, :must_be_from_different_accounts if accounts.size < entries.size
    end

    def net_zero_flows
      unless entries.sum(&:amount).zero?
        errors.add :entries, :must_have_an_inflow_and_outflow_that_net_to_zero
      end
    end

    def all_transactions_marked
      unless entries.all? { |e| e.entryable.category == from_account.family.default_transfer_category }
        errors.add :entries, :must_have_transfer_category
      end
    end
end
