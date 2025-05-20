class Account::MarketDataImporter
  attr_reader :account

  def initialize(account)
    @account = account
  end

  def import_all
    import_exchange_rates
    import_security_prices
  end

  def import_exchange_rates
    return unless needs_exchange_rates?
    return unless ExchangeRate.provider

    pair_dates = {}

    # 1. ENTRY-BASED PAIRS – currencies that differ from the account currency
    account.entries
           .where.not(currency: account.currency)
           .group(:currency)
           .minimum(:date)
           .each do |source_currency, date|
      key = [ source_currency, account.currency ]
      pair_dates[key] = [ pair_dates[key], date ].compact.min
    end

    # 2. ACCOUNT-BASED PAIR – convert the account currency to the family currency (if different)
    if foreign_account?
      key = [ account.currency, account.family.currency ]
      pair_dates[key] = [ pair_dates[key], account.start_date ].compact.min
    end

    pair_dates.each do |(source, target), start_date|
      ExchangeRate.import_provider_rates(
        from: source,
        to: target,
        start_date: start_date,
        end_date: Date.current
      )
    end
  end

  def import_security_prices
    return unless Security.provider

    account_securities = account.trades.map(&:security).uniq

    return if account_securities.empty?

    account_securities.each do |security|
      security.import_provider_prices(
        start_date: first_required_price_date(security),
        end_date: Date.current
      )

      security.import_provider_details
    end
  end

  private
    # Calculates the first date we require a price for the given security scoped to this account
    def first_required_price_date(security)
      account.trades.with_entry
                    .where(security: security)
                    .where(entries: { account_id: account.id })
                    .minimum("entries.date")
    end

    def needs_exchange_rates?
      has_multi_currency_entries? || foreign_account?
    end

    def has_multi_currency_entries?
      account.entries.where.not(currency: account.currency).exists?
    end

    def foreign_account?
      account.currency != account.family.currency
    end
end
