class Investment < ApplicationRecord
  include Accountable

  SUBTYPES = [
    [ "Brokerage", "brokerage" ],
    [ "Pension", "pension" ],
    [ "Retirement", "retirement" ],
    [ "401(k)", "401k" ],
    [ "Traditional 401(k)", "traditional_401k" ],
    [ "Roth 401(k)", "roth_401k" ],
    [ "529 Plan", "529_plan" ],
    [ "Health Savings Account", "hsa" ],
    [ "Mutual Fund", "mutual_fund" ],
    [ "Traditional IRA", "traditional_ira" ],
    [ "Roth IRA", "roth_ira" ],
    [ "Angel", "angel" ]
  ].freeze

  def value
    account.balance_money + holdings_value
  end

  def holdings_value
    account.holdings.current.known_value.sum(&:amount) || Money.new(0, account.currency)
  end

  def series(period: Period.all, currency: account.currency)
    balance_series = account.balances.in_period(period).where(currency: currency)
    holding_series = account.holdings.known_value.in_period(period).where(currency: currency)

    holdings_by_date = holding_series.group_by(&:date).transform_values do |holdings|
      holdings.sum(&:amount)
    end

    combined_series = balance_series.map do |balance|
      holding_amount = holdings_by_date[balance.date] || 0

      { date: balance.date, value: Money.new(balance.balance + holding_amount, currency) }
    end

    if combined_series.empty? && period.date_range.end == Date.current
      TimeSeries.new([ { date: Date.current, value: self.value.exchange_to(currency) } ])
    else
      TimeSeries.new(combined_series)
    end
  rescue Money::ConversionError
    TimeSeries.new([])
  end
end
