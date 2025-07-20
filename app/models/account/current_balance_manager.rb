class Account::CurrentBalanceManager
  InvalidOperation = Class.new(StandardError)

  Result = Struct.new(:success?, :changes_made?, :error, keyword_init: true)

  def initialize(account)
    @account = account
  end

  def has_current_anchor?
    current_anchor_valuation.present?
  end

  # Our system should always make sure there is a current anchor, and that it is up to date.
  # The fallback is provided for backwards compatibility, but should not be relied on since account.balance is a "cached/derived" value.
  def current_balance
    if current_anchor_valuation
      current_anchor_valuation.entry.amount
    else
      Rails.logger.warn "No current balance anchor found for account #{account.id}. Using cached balance instead, which may be out of date."
      account.balance
    end
  end

  def current_date
    if current_anchor_valuation
      current_anchor_valuation.entry.date
    else
      Date.current
    end
  end

  def set_current_balance(balance)
    if account.linked?
      result = set_current_balance_for_linked_account(balance)
    else
      result = set_current_balance_for_manual_account(balance)
    end

    # Update cache field so changes appear immediately to the user
    account.update!(balance: balance)

    result
  rescue => e
    Result.new(success?: false, changes_made?: false, error: e.message)
  end

  private
    attr_reader :account

    def opening_balance_manager
      @opening_balance_manager ||= Account::OpeningBalanceManager.new(account)
    end

    def reconciliation_manager
      @reconciliation_manager ||= Account::ReconciliationManager.new(account)
    end

    # Manual accounts do not manage the `current_anchor` valuation (otherwise, user would need to continually update it, which is bad UX)
    # Instead, we use a combination of "auto-update strategies" to set the current balance according to the user's intent.
    #
    # The "auto-update strategies" are:
    # 1. Value tracking - If the account has a reconciliation already, we assume they are tracking the account value primarily with reconciliations, so we append a new one
    # 2. Transaction adjustment - If the account doesn't have recons, we assume user is tracking with transactions, so we adjust the opening balance with a delta until it
    #                             gets us to the desired balance. This ensures we don't append unnecessary reconciliations to the account, which "reset" the value from that
    #                             date forward (not user's intent).
    #
    # For more documentation on these auto-update strategies, see the test cases.
    def set_current_balance_for_manual_account(balance)
      # If we're dealing with a cash account that has no reconciliations, use "Transaction adjustment" strategy (update opening balance to "back in" to the desired current balance)
      if account.balance_type == :cash && account.valuations.reconciliation.empty?
        adjust_opening_balance_with_delta(new_balance: balance, old_balance: account.balance)
      else
        existing_reconciliation = account.entries.valuations.find_by(date: Date.current)

        result = reconciliation_manager.reconcile_balance(balance: balance, date: Date.current, existing_valuation_entry: existing_reconciliation)

        # Normalize to expected result format
        Result.new(success?: result.success?, changes_made?: true, error: result.error_message)
      end
    end

    def adjust_opening_balance_with_delta(new_balance:, old_balance:)
      delta = new_balance - old_balance

      result = opening_balance_manager.set_opening_balance(balance: account.opening_anchor_balance + delta)

      # Normalize to expected result format
      Result.new(success?: result.success?, changes_made?: true, error: result.error)
    end

    # Linked accounts manage "current balance" via the special `current_anchor` valuation.
    # This is NOT a user-facing feature, and is primarily used in "processors" while syncing
    # linked account data (e.g. via Plaid)
    def set_current_balance_for_linked_account(balance)
      if current_anchor_valuation
        changes_made = update_current_anchor(balance)
        Result.new(success?: true, changes_made?: changes_made, error: nil)
      else
        create_current_anchor(balance)
        Result.new(success?: true, changes_made?: true, error: nil)
      end
    end

    def current_anchor_valuation
      @current_anchor_valuation ||= account.valuations.current_anchor.includes(:entry).first
    end

    def create_current_anchor(balance)
      account.entries.create!(
        date: Date.current,
        name: Valuation.build_current_anchor_name(account.accountable_type),
        amount: balance,
        currency: account.currency,
        entryable: Valuation.new(kind: "current_anchor")
      )
    end

    def update_current_anchor(balance)
      changes_made = false

      ActiveRecord::Base.transaction do
        # Update associated entry attributes
        entry = current_anchor_valuation.entry

        if entry.amount != balance
          entry.amount = balance
          changes_made = true
        end

        if entry.date != Date.current
          entry.date = Date.current
          changes_made = true
        end

        entry.save! if entry.changed?
      end

      changes_made
    end
end
