class Account::Balance::Syncer
  def initialize(account, start_date: nil)
    @account = account
    @provided_start_date = start_date
    @sync_start_date = calculate_sync_start_date(start_date)
    @loader = Account::Balance::Loader.new(account)
    @converter = Account::Balance::Converter.new(account, sync_start_date)
    @calculator = Account::Balance::Calculator.new(account, sync_start_date)
  end

  def run
    daily_balances = calculator.calculate(is_partial_sync: is_partial_sync?)
    daily_balances += converter.convert(daily_balances) if account.currency != account.family.currency

    loader.load(daily_balances, account_start_date)
  rescue Money::ConversionError => e
    account.observe_missing_exchange_rates(from: e.from_currency, to: e.to_currency, dates: [ e.date ])
  end

  private

    attr_reader :sync_start_date, :provided_start_date, :account, :loader, :converter, :calculator

    def account_start_date
      @account_start_date ||= begin
                                oldest_entry = account.entries.chronological.first

                                return Date.current unless oldest_entry.present?

                                if oldest_entry.account_valuation?
                                  oldest_entry.date
                                else
                                  oldest_entry.date - 1.day
                                end
                              end
    end

    def calculate_sync_start_date(provided_start_date)
      return provided_start_date if provided_start_date.present? && prior_balance_available?(provided_start_date)

      account_start_date
    end

    def prior_balance_available?(date)
      account.balances.find_by(currency: account.currency, date: date - 1.day).present?
    end

    def is_partial_sync?
      sync_start_date == provided_start_date && sync_start_date < Date.current
    end
end
