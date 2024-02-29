class Account < ApplicationRecord
  include Syncable

  broadcasts_refreshes
  belongs_to :family
  has_many :balances, class_name: "AccountBalance"
  has_many :valuations
  has_many :transactions

  delegated_type :accountable, types: Accountable::TYPES, dependent: :destroy

  delegate :type_name, to: :accountable
  before_create :check_currency

  # Represents the earliest date we can calculate an account balance for
  def effective_start_date
    first_valuation_date = valuations.order(:date).pluck(:date).first
    first_transaction_date = transactions.order(:date).pluck(:date).first

    [ first_valuation_date, first_transaction_date&.prev_day ].compact.min || Date.current
  end

  def balance_series(period)
    filtered_balances = balances.in_period(period).order(:date)
    return nil if filtered_balances.empty?

    series_data = [ nil, *filtered_balances ].each_cons(2).map do |previous, current|
      trend = current&.trend(previous)
      { data: current, trend: { amount: trend&.amount, direction: trend&.direction, percent: trend&.percent } }
    end

    last_balance = series_data.last[:data]

    {
      series_data: series_data,
      last_balance: last_balance.balance,
      trend: last_balance.trend(series_data.first[:data])
    }
  end

  def valuation_series
    series_data = [ nil, *valuations.order(:date) ].each_cons(2).map do |previous, current|
      { value: current, trend: current&.trend(previous) }
    end

    series_data.reverse_each
  end

  def check_currency
    if self.currency == self.family.currency
      self.converted_balance = self.balance
      self.converted_currency = self.currency
    else
      self.converted_balance = ExchangeRate.convert(self.currency, self.family.currency, self.balance)
      self.converted_currency = self.family.currency
    end
  end
end
