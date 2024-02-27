class Account < ApplicationRecord
  broadcasts_refreshes
  belongs_to :family
  has_many :balances, class_name: "AccountBalance"
  has_many :valuations
  has_many :transactions

  delegated_type :accountable, types: Accountable::TYPES, dependent: :destroy

  delegate :type_name, to: :accountable
  before_create :check_currency

  def sync(start_date: nil)
    AccountSyncJob.perform_later(account_id: self.id, start_date: start_date)
  end

  def effective_start_date
    start_date ||
      [ valuations, transactions ].map { |relation|
        relation.order(:date).pluck(:date).first
      }.compact.min ||
      7.days.ago.to_date
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
    if self.original_currency == self.family.currency
      self.converted_balance = self.original_balance
      self.converted_currency = self.original_currency
    else
      self.converted_balance = ExchangeRate.convert(self.original_currency, self.family.currency, self.original_balance)
      self.converted_currency = self.family.currency
    end
  end
end
