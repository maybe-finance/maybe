module Account::Convertible
  extend ActiveSupport::Concern

  def sync_required_exchange_rates
    unless requires_exchange_rates?
      Rails.logger.info("No exchange rate sync needed for account #{id}")
      return
    end

    rates = ExchangeRate.find_rates(
      from: currency,
      to: target_currency,
      start_date: start_date,
      cache: true # caches from provider to DB
    )

    Rails.logger.info("Synced #{rates.count} exchange rates for account #{id}")
  end

  private
    def target_currency
      family.currency
    end

    def requires_exchange_rates?
      currency != target_currency
    end
end
