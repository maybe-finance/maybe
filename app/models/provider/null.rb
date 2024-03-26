class Provider::Null < Provider::Base
  def initialize(...)
  end

  def fetch_exchange_rate(...)
    raise Provider::Base::UnsupportedOperationError.new \
      "#{self.class.name} cannot fetch exchange rates"
  end

  def fetch_merchant_data(...)
    raise Provider::Base::UnsupportedOperationError.new \
      "#{self.class.name} cannot fetch merchant data"
  end

  def fetch_real_estate_valuation(...)
    raise Provider::Base::UnsupportedOperationError.new \
      "#{self.class.name} cannot fetch real estate valuations"
  end
end
