class Valuation < ApplicationRecord
  belongs_to :account

  def trend(previous)
    Trend.new(value, previous&.value)
  end
end
