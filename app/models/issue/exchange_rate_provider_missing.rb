class Issue::ExchangeRateProviderMissing < Issue
  def default_severity
    :error
  end

  def stale?
    ExchangeRate.exchange_rates_provider.present?
  end
end
