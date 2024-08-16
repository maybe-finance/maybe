class Issue::ExchangeRateProviderMissing < Issue
  def default_severity
    :error
  end

  def stale?
    ExchangeRate.provider_healthy?
  end
end
