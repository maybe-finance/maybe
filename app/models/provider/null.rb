class Provider::Null
  def initialize(...)
  end

  def fetch_exchange_rate(...)
    raise Provider::Base::UnsupportedOperationError.new \
      "You need to configure a provider to fetch exchange rates"
  end
end
