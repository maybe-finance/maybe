class Account::BalanceUpdater
  def initialize(account, balance:, currency: nil, date: Date.current, notes: nil)
    @account = account
    @balance = balance.to_d
    @currency = currency
    @date = date.to_date
    @notes = notes
  end

  def update
    return Result.new(success?: true, updated?: false) unless requires_update?

    Account.transaction do
      if date == Date.current
        account.balance = balance
        account.currency = currency if currency.present?
        account.save!
      end

      valuation_entry = account.entries.valuations.find_or_initialize_by(date: date) do |entry|
        entry.entryable = Valuation.new
      end

      valuation_entry.amount = balance
      valuation_entry.currency = currency if currency.present?
      valuation_entry.name = valuation_name(valuation_entry.entryable, account)
      valuation_entry.notes = notes if notes.present?
      valuation_entry.save!
    end

    account.sync_later

    Result.new(success?: true, updated?: true)
  rescue => e
    message = Rails.env.development? ? e.message : "Unable to update account values. Please try again."
    Result.new(success?: false, updated?: false, error_message: message)
  end

  private
    attr_reader :account, :balance, :currency, :date, :notes

    Result = Struct.new(:success?, :updated?, :error_message)

    def requires_update?
      date != Date.current || account.balance != balance || account.currency != currency
    end

    def valuation_name(valuation_entry, account)
      Valuation::Name.new(valuation_entry.entryable.kind, account.accountable_type).to_s
    end
end
