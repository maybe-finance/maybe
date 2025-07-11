class Account::OpeningBalanceManager
  def initialize(account)
    @account = account
  end

  def set_opening_balance(balance:, cash_balance: nil, date: nil)
    if opening_anchor_valuation.nil?
      create_opening_anchor(
        balance: balance,
        cash_balance: cash_balance || default_cash_balance(balance),
        date: date || default_date
      )
    else
      update_opening_anchor(balance: balance, cash_balance: cash_balance, date: date)
    end
  end

  private
    Result = Struct.new(:success?, :changes_made?, :error)

    def opening_anchor_valuation
      @opening_anchor_valuation ||= valuations.opening_anchor.includes(:entry).first
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
      (account.entries.minimum(:date) - 1.day) || 2.years.ago.to_date
    end

    def create_opening_anchor(balance:, cash_balance:, date:)
      account.entries.create(
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
      ActiveRecord::Base.transaction do
        opening_anchor_valuation.balance = balance
        opening_anchor_valuation.cash_balance = cash_balance if cash_balance.present?
        opening_anchor_valuation.save!

        opening_anchor_valuation.entry.amount = balance
        opening_anchor_valuation.entry.date = date if date.present?
        opening_anchor_valuation.entry.save!
      end
    end
end
