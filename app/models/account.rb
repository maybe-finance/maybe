class Account < ApplicationRecord
  belongs_to :family
  has_many :balances, class_name: "AccountBalance"
  has_many :valuations

  delegated_type :accountable, types: Accountable::TYPES, dependent: :destroy

  delegate :type_name, to: :accountable

  before_create :check_currency

  # Show all valuations in history table (no date range filtering)
  def valuations_with_trend
    series_for(valuations, :value)
  end

  def balances_with_trend(date_range = default_date_range)
    series_for(balances, :balance, date_range)
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

  private

    def default_date_range
      { start: 30.days.ago.to_date, end: Date.today }
    end

    # TODO: probably a better abstraction for this in the future
    def series_for(collection, value_attr, date_range = {})
      collection = filtered_by_date_for(collection, date_range)
      overall_trend = Trend.new(collection.last&.send(value_attr), collection.first&.send(value_attr))

      collection_with_trends = [ nil, *collection ].each_cons(2).map do |previous, current|
        {
          previous: previous,
          date: current.date,
          currency: current.currency,
          value: current.send(value_attr),
          trend: Trend.new(current.send(value_attr), previous&.send(value_attr))
        }
      end

      { date_range: date_range, trend: overall_trend, series: collection_with_trends }
    end

    def filtered_by_date_for(association, date_range)
      scope = association
      scope = scope.where("date >= ?", date_range[:start]) if date_range[:start]
      scope = scope.where("date <= ?", date_range[:end]) if date_range[:end]
      scope.order(:date).to_a
    end
end
