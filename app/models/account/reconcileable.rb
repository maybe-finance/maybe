# Methods for updating the historical balances of an account (opening, current, and arbitrary date reconciliations)
module Account::Reconcileable
  extend ActiveSupport::Concern

  included do
    include Monetizable

    monetize :balance, :cash_balance, :non_cash_balance
  end

  InvalidBalanceError = Class.new(StandardError)

  # For depository accounts, this is 0 (total balance is liquid cash)
  # For all other accounts, this represents "asset value" or "debt value"
  # (i.e. Investment accounts would refer to this as "holdings value")
  def non_cash_balance
    balance - cash_balance
  end

  def opening_balance
    @opening_balance ||= opening_anchor_valuation&.balance
  end

  def opening_cash_balance
    @opening_cash_balance ||= opening_anchor_valuation&.cash_balance
  end

  def opening_date
    @opening_date ||= opening_anchor_valuation&.entry&.date
  end

  def reconcile_balance!(balance:, cash_balance:, date:)
    raise InvalidBalanceError, "Cash balance cannot exceed balance" if cash_balance > balance
    raise InvalidBalanceError, "Linked accounts cannot be reconciled" if linked?

    existing_valuation = valuations.joins(:entry).where(kind: "recon", entry: { date: date }).first

    transaction do
      if existing_valuation.present?
        existing_valuation.update!(
          balance: balance,
          cash_balance: cash_balance
        )
      else
        entries.create!(
          date: date,
          name: Valuation::Name.new("recon", self.accountable_type),
          amount: balance,
          currency: self.currency,
          entryable: Valuation.new(
            kind: "recon",
            balance: balance,
            cash_balance: cash_balance
          )
        )
      end

      # Update cached balance fields on account when reconciling for current date
      if date == Date.current
        update!(balance: balance, cash_balance: cash_balance)
      end
    end
  end

  def update_current_balance!(balance:, cash_balance:)
    raise InvalidBalanceError, "Cash balance cannot exceed balance" if cash_balance > balance

    transaction do
      if opening_anchor_valuation.present? && valuations.where(kind: "recon").empty?
        adjust_opening_balance_with_delta(balance:, cash_balance:)
      else
        reconcile_balance!(balance:, cash_balance:, date: Date.current)
      end

      # Always update cached balance fields when updating current balance
      update!(balance: balance, cash_balance: cash_balance)
    end
  end

  def adjust_opening_balance_with_delta(balance:, cash_balance:)
    delta = self.balance - balance
    cash_delta = self.cash_balance - cash_balance

    set_or_update_opening_balance!(
      balance: balance - delta,
      cash_balance: cash_balance - cash_delta
    )
  end

  def set_or_update_opening_balance!(balance:, cash_balance:, date: nil)
    # A reasonable start date for most accounts to fill up adequate history for graphs
    fallback_opening_date = 2.years.ago.to_date

    raise InvalidBalanceError, "Cash balance cannot exceed balance" if cash_balance > balance

    transaction do
      if opening_anchor_valuation
        opening_anchor_valuation.update!(
          balance: balance,
          cash_balance: cash_balance
        )

        opening_anchor_valuation.entry.update!(amount: balance)
        opening_anchor_valuation.entry.update!(date: date) unless date.nil?

        opening_anchor_valuation
      else
        entry = entries.create!(
          date: date || fallback_opening_date,
          name: Valuation::Name.new("opening_anchor", self.accountable_type),
          amount: balance,
          currency: self.currency,
          entryable: Valuation.new(
            kind: "opening_anchor",
            balance: balance,
            cash_balance: cash_balance,
          )
        )

        entry.valuation
      end
    end
  end

  private
    def opening_anchor_valuation
      @opening_anchor_valuation ||= valuations.opening_anchor.includes(:entry).first
    end

    def current_anchor_valuation
      valuations.current_anchor.first
    end
end
