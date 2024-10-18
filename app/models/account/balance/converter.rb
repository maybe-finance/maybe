class Account::Balance::Converter
  def initialize(account, sync_start_date)
    @account = account
    @sync_start_date = sync_start_date
  end

  def convert(balances)
    calculate_converted_balances(balances)
  end

  private
    attr_reader :account, :sync_start_date

    def calculate_converted_balances(balances)
      from_currency = account.currency
      to_currency = account.family.currency

      if ExchangeRate.exchange_rates_provider.nil?
        account.observe_missing_exchange_rate_provider
        return []
      end

      exchange_rates = ExchangeRate.find_rates from: from_currency,
                                               to: to_currency,
                                               start_date: sync_start_date

      missing_exchange_rates = balances.map(&:date) - exchange_rates.map(&:date)

      if missing_exchange_rates.any?
        account.observe_missing_exchange_rates(from: from_currency, to: to_currency, dates: missing_exchange_rates)
        return []
      end

      balances.map do |balance|
        exchange_rate = exchange_rates.find { |er| er.date == balance.date }
        build_balance(balance.date, exchange_rate.rate * balance.balance, to_currency)
      end
    end

    def build_balance(date, balance, currency = nil)
      account.balances.build \
        date: date,
        balance: balance,
        currency: currency || account.currency
    end
end
