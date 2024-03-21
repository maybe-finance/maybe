class ExchangeRate < ApplicationRecord
  validates :base_currency, :converted_currency, presence: true

  def self.convert(from, to, amount)
    rate = ExchangeRate.find_by(base_currency: from, converted_currency: to, date: Date.current)
    return nil if rate.nil?
    amount * rate.rate
  end

  def self.get_rate(from, to, date)
    _from = Money::Currency.new(from)
    _to = Money::Currency.new(to)
    find_by(base_currency: _from.iso_code, converted_currency: _to.iso_code, date: date)
  end
end
