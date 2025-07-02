class Account::BalanceUpdater
  def initialize(account, balance:, currency: nil, date: Date.current)
    @account = account
    @balance = balance
    @currency = currency
    @date = date
  end

  def update
    return Result.new(success?: true, updated?: false) unless requires_update?

    Account.transaction do
      if date == Date.current
        account.update!(balance: balance, currency: currency)
      end

      valuation_entry = account.entries.valuations.find_or_initialize_by(date: date) do |entry|
        entry.entryable = Valuation.new
      end

      valuation_entry.amount = balance
      valuation_entry.currency = currency
      valuation_entry.name = "Manual #{account.accountable.balance_display_name} update"
      valuation_entry.save!
    end

    Result.new(success?: true, updated?: true)
  rescue => e
    message = Rails.env.development? ? e.message : "Unable to update account values. Please try again."
    Result.new(success?: false, updated?: false, error_message: message)
  end

  private
    attr_reader :account, :balance, :currency, :date

    Result = Struct.new(:success?, :updated?, :error_message)

    def requires_update?
      date != Date.current || account.balance != balance.to_d || account.currency != currency
    end
end
