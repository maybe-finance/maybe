class ExchangeRate < ApplicationRecord
  def self.convert(from, to, amount)
    rate = ExchangeRate.find_by(base_currency: from, converted_currency: to, date: Date.current)

    if rate.nil?
      raise "Rate for #{from} to #{to} not found"
    else
      amount * rate.rate
    end
  end
end
