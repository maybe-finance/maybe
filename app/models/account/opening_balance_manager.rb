class Account::OpeningBalanceManager
  Result = Struct.new(:success?, :changes_made?, :error, keyword_init: true)

  def initialize(account)
    @account = account
  end

  def has_opening_anchor?
    opening_anchor_valuation.present?
  end

  # Most accounts should have an opening anchor. If not, we derive the opening date from the oldest entry date
  def opening_date
    return opening_anchor_valuation.entry.date if opening_anchor_valuation.present?

    [
      account.entries.valuations.order(:date).first&.date,
      account.entries.where.not(entryable_type: "Valuation").order(:date).first&.date&.prev_day
    ].compact.min || Date.current
  end

  def opening_balance
    opening_anchor_valuation&.entry&.amount || 0
  end

  def set_opening_balance(balance:, date: nil)
    resolved_date = date || default_date

    # Validate date is before oldest entry
    if date && oldest_entry_date && resolved_date >= oldest_entry_date
      return Result.new(success?: false, changes_made?: false, error: "Opening balance date must be before the oldest entry date")
    end

    if opening_anchor_valuation.nil?
      create_opening_anchor(
        balance: balance,
        date: resolved_date
      )
      Result.new(success?: true, changes_made?: true, error: nil)
    else
      changes_made = update_opening_anchor(balance: balance, date: date)
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

    def default_date
      if oldest_entry_date
        [ oldest_entry_date - 1.day, 2.years.ago.to_date ].min
      else
        2.years.ago.to_date
      end
    end

    def create_opening_anchor(balance:, date:)
      account.entries.create!(
        date: date,
        name: Valuation.build_opening_anchor_name(account.accountable_type),
        amount: balance,
        currency: account.currency,
        entryable: Valuation.new(
          kind: "opening_anchor"
        )
      )
    end

    def update_opening_anchor(balance:, date: nil)
      changes_made = false

      ActiveRecord::Base.transaction do
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
