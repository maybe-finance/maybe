module Account::Transaction::Aggregatable
  extend ActiveSupport::Concern

  included do
    # All non-excluded, non-transfer, rejected transfers, and the outflow of a loan payment transfer are incomes/expenses
    scope :incomes_and_expenses, -> {
      with_entry
        .joins("LEFT JOIN transfers ON transfers.inflow_transaction_id = account_entries.id OR transfers.outflow_transaction_id = account_entries.id")
        .joins("LEFT JOIN account_transactions inflow_txns ON inflow_txns.id = transfers.inflow_transaction_id")
        .joins("LEFT JOIN account_entries inflow_entries ON inflow_entries.entryable_id = inflow_txns.id AND inflow_entries.entryable_type = 'Account::Transaction'")
        .joins("LEFT JOIN accounts inflow_accounts ON inflow_accounts.id = inflow_entries.account_id")
        .where("transfers.id IS NULL OR transfers.status = 'rejected' OR (account_entries.amount > 0 AND inflow_accounts.accountable_type = 'Loan')")
        .where(account_entries: { excluded: false })
    }

    scope :incomes, -> {
      incomes_and_expenses.where("account_entries.amount <= 0")
    }

    scope :expenses, -> {
      incomes_and_expenses.where("account_entries.amount > 0")
    }
  end

  class_methods do
    def stats(currency)
      result = all.incomes_and_expenses
        .joins(sanitize_sql_array([
          "LEFT JOIN exchange_rates er ON account_entries.date = er.date AND account_entries.currency = er.from_currency AND er.to_currency = ?",
          currency
        ]))
        .select(
          "COUNT(*) AS count",
          sanitize_sql_array([ "COUNT(CASE WHEN account_entries.currency != ? AND er.rate IS NULL THEN 1 END) as missing_rates", currency ]),
          "SUM(CASE WHEN account_entries.amount < 0 THEN (account_entries.amount * COALESCE(er.rate, 1)) ELSE 0 END) AS income_total",
          "SUM(CASE WHEN account_entries.amount > 0 THEN (account_entries.amount * COALESCE(er.rate, 1)) ELSE 0 END) AS expense_total"
        )
        .to_a
        .first

      response_struct = Struct.new(:currency, :count, :income_total, :expense_total, :missing_rates?, keyword_init: true)

      response_struct.new(
        currency: currency,
        count: result.count,
        income_total: result.income_total ? result.income_total * -1 : 0,
        expense_total: result.expense_total || 0,
        missing_rates?: result.missing_rates.to_i > 0
      )
    end
  end
end
