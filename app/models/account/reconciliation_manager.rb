class Account::ReconciliationManager
  attr_reader :account

  def initialize(account)
    @account = account
  end

  # Reconciles balance by creating a Valuation entry. If existing valuation is provided, it will be updated instead of creating a new one.
  def reconcile_balance(balance:, date: Date.current, dry_run: false, existing_valuation_entry: nil)
    old_balance_components = old_balance_components(reconciliation_date: date, existing_valuation_entry: existing_valuation_entry)
    prepared_valuation = prepare_reconciliation(balance, date, existing_valuation_entry)

    unless dry_run
      prepared_valuation.save!
    end

    ReconciliationResult.new(
      success?: true,
      old_cash_balance: old_balance_components[:cash_balance],
      old_balance: old_balance_components[:balance],
      new_cash_balance: derived_cash_balance(date: date, total_balance: prepared_valuation.amount),
      new_balance: prepared_valuation.amount,
      error_message: nil
    )
  rescue => e
    ReconciliationResult.new(
      success?: false,
      error_message: e.message
    )
  end

  private
    # Returns before -> after OR error message
    ReconciliationResult = Struct.new(
      :success?,
      :old_cash_balance,
      :old_balance,
      :new_cash_balance,
      :new_balance,
      :error_message,
      keyword_init: true
    )

    def prepare_reconciliation(balance, date, existing_valuation)
      valuation_record = existing_valuation ||
                         account.entries.valuations.find_by(date: date) || # In case of conflict, where existing valuation is not passed as arg, but one exists
                         account.entries.build(
                                  name: Valuation.build_reconciliation_name(account.accountable_type),
                                  entryable: Valuation.new(kind: "reconciliation")
                                )

      valuation_record.assign_attributes(
        date: date,
        amount: balance,
        currency: account.currency
      )

      valuation_record
    end

    def derived_cash_balance(date:, total_balance:)
      balance_components_for_reconciliation_date = get_balance_components_for_date(date)

      return nil unless balance_components_for_reconciliation_date[:balance] && balance_components_for_reconciliation_date[:cash_balance]

      # We calculate the existing non-cash balance, which for investments would represents "holdings" for the date of reconciliation
      # Since the user is setting "total balance", we have to subtract the existing non-cash balance from the total balance to get the new cash balance
      existing_non_cash_balance = balance_components_for_reconciliation_date[:balance] - balance_components_for_reconciliation_date[:cash_balance]

      total_balance - existing_non_cash_balance
    end

    def old_balance_components(reconciliation_date:, existing_valuation_entry: nil)
      if existing_valuation_entry
        get_balance_components_for_date(existing_valuation_entry.date)
      else
        get_balance_components_for_date(reconciliation_date)
      end
    end

    def get_balance_components_for_date(date)
      balance_record = account.balances.find_by(date: date, currency: account.currency)

      {
        cash_balance: balance_record&.cash_balance,
        balance: balance_record&.balance
      }
    end
end
