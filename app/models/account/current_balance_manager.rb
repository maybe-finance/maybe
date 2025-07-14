class Account::CurrentBalanceManager
  InvalidOperation = Class.new(StandardError)

  Result = Struct.new(:success?, :changes_made?, :error, keyword_init: true)

  def initialize(account)
    @account = account
  end

  def has_current_anchor?
    current_anchor_valuation.present?
  end

  # The fallback here is not ideal. We should not be relying on `account.balance` as it is a "cached/derived" value, set
  # by the balance calculators. Our system should always make sure there is a current anchor, and that it is up to date.
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
    # A current balance anchor implies there is an external data source that will keep it updated. Since manual accounts
    # are tracked by the user, a current balance anchor is not appropriate.
    raise InvalidOperation, "Manual accounts cannot set current balance anchor. Set opening balance or use a reconciliation instead." if account.manual?

    if current_anchor_valuation
      changes_made = update_current_anchor(balance)
      Result.new(success?: true, changes_made?: changes_made, error: nil)
    else
      create_current_anchor(balance)
      Result.new(success?: true, changes_made?: true, error: nil)
    end
  end

  private
    attr_reader :account

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
