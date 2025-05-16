module Account::Convertible
  extend ActiveSupport::Concern

  def sync_required_exchange_rates
    unless requires_exchange_rates?
      Rails.logger.info("No exchange rate sync needed for account #{id}")
      return
    end

    affected_row_count = ExchangeRate.sync_provider_rates(
      from: currency,
      to: target_currency,
      start_date: start_date,
      end_date: Date.current
    )

    Rails.logger.info("Synced #{affected_row_count} exchange rates for account #{id}")
  end

  private
    def target_currency
      family.currency
    end

    def requires_exchange_rates?
      currency != target_currency
    end
end
