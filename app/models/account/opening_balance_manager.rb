class Account::OpeningBalanceManager
  Result = Struct.new(:success?, :changes_made?, :error, keyword_init: true)

  def initialize(account)
    @account = account
  end

  def set_opening_balance(balance:, cash_balance: nil, date: nil)
    resolved_date = date || default_date
    resolved_cash_balance = cash_balance || default_cash_balance(balance)

    # Validate date is before oldest entry
    if date && oldest_entry_date && resolved_date >= oldest_entry_date
      return Result.new(success?: false, changes_made?: false, error: "Opening balance date must be before the oldest entry date")
    end

    if opening_anchor_valuation.nil?
      create_opening_anchor(
        balance: balance,
        cash_balance: resolved_cash_balance,
        date: resolved_date
      )
      Result.new(success?: true, changes_made?: true, error: nil)
    else
      changes_made = update_opening_anchor(balance: balance, cash_balance: cash_balance, date: date)
      Result.new(success?: true, changes_made?: changes_made, error: nil)
    end
  end

  private
    attr_reader :account

    def opening_anchor_valuation
      @opening_anchor_valuation ||= account.valuations.opening_anchor.includes(:entry).first
    end

    def oldest_entry_date
      @oldest_entry_date ||= account.entries.minimum(:date)
    end

    # Depository accounts are "all cash" accounts, so cash_balance and balance are the same. All other types are "non-cash" accounts
    def default_cash_balance(balance)
      case account.accountable_type
      when "Depository"
        balance
      else
        0
      end
    end

    def default_date
      if oldest_entry_date
        [ oldest_entry_date - 1.day, 2.years.ago.to_date ].min
      else
        2.years.ago.to_date
      end
    end

    def create_opening_anchor(balance:, cash_balance:, date:)
      account.entries.create!(
        date: date,
        name: Valuation.build_opening_anchor_name(account.accountable_type),
        amount: balance,
        currency: account.currency,
        entryable: Valuation.new(
          kind: "opening_anchor",
          balance: balance,
          cash_balance: cash_balance
        )
      )
    end

    def update_opening_anchor(balance:, cash_balance: nil, date: nil)
      changes_made = false

      ActiveRecord::Base.transaction do
        # Update valuation attributes
        if opening_anchor_valuation.balance != balance
          opening_anchor_valuation.balance = balance
          changes_made = true
        end

        if cash_balance.present? && opening_anchor_valuation.cash_balance != cash_balance
          opening_anchor_valuation.cash_balance = cash_balance
          changes_made = true
        end

        opening_anchor_valuation.save! if opening_anchor_valuation.changed?

        # Update associated entry attributes
        entry = opening_anchor_valuation.entry

        if entry.amount != balance
          entry.amount = balance
          changes_made = true
        end

        if date.present? && entry.date != date
          entry.date = date
          changes_made = true
        end

        entry.save! if entry.changed?
      end

      changes_made
    end
end
