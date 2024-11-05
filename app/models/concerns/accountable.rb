module Accountable
  extend ActiveSupport::Concern

  ASSET_TYPES = %w[Depository Investment Crypto Property Vehicle OtherAsset]
  LIABILITY_TYPES = %w[CreditCard Loan OtherLiability]
  TYPES = ASSET_TYPES + LIABILITY_TYPES

  def self.from_type(type)
    return nil unless TYPES.include?(type)
    type.constantize
  end

  def self.by_classification
    { assets: ASSET_TYPES, liabilities: LIABILITY_TYPES }
  end

  included do
    has_one :account, as: :accountable, touch: true
  end

  def value
    account.balance_money
  end

  def series(period: Period.all, currency: account.currency)
    balance_series = account.balances.in_period(period).where(currency: currency)

    if balance_series.empty? && period.date_range.end == Date.current
      TimeSeries.new([ { date: Date.current, value: account.balance_money.exchange_to(currency) } ])
    else
      TimeSeries.from_collection(balance_series, :balance_money, favorable_direction: account.asset? ? "up" : "down")
    end
  rescue Money::ConversionError
    TimeSeries.new([])
  end
end
