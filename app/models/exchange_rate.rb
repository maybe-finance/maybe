class ExchangeRate < ApplicationRecord
  def self.convert(from, to, amount)
    rate = ExchangeRate.find_by(base_currency: from, converted_currency: to)
    amount * rate.rate
  end
end
