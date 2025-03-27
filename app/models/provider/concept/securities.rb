module Provider::Concept::Securities
  extend ActiveSupport::Concern

  def fetch_security_price(symbol:, date:)
    raise NotImplementedError, "Subclasses must implement #fetch_security_price"
  end
end
