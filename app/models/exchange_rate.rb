class ExchangeRate < ApplicationRecord
  def self.convert(from, to, amount)
    return amount unless EXCHANGE_RATE_ENABLED

    rate = ExchangeRate.find_by(base_currency: from, converted_currency: to)

    # TODO: Handle the case where the rate is not found
    if rate.nil?
      amount # Silently handle the error by returning the original amount
    else
      amount * rate.rate
    end
  end
end
