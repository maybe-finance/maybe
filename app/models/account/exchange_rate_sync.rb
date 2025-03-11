class Account::ExchangeRateSync
  def initialize(account)
    @account = account
  end

  def sync_rates
    Rails.logger.tagged("Account::ExchangeRateSync") do
      unless needs_rate_sync?
        Rails.logger.info("No exchange rate sync needed for account #{@account.id}")
        return
      end

      rates = ExchangeRate.find_rates(
        from: @account.currency,
        to: target_currency,
        start_date: @account.start_date,
        cache: true # caches from provider to DB
      )

      Rails.logger.info("Synced #{rates.count} exchange rates for account #{@account.id}")
    end
  end

  private
    def target_currency
      @account.family.currency
    end

    def needs_rate_sync?
      @account.currency != target_currency
    end
end
