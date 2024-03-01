class Family < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :accounts, dependent: :destroy
  has_many :transactions, through: :accounts

  def net_worth
    assets - liabilities
  end

  def assets
    accounts.reduce(0) do |sum, account|
      sum += account.balance if account.classification == :asset
      sum
    end
  end

  def liabilities
    accounts.reduce(0) do |sum, account|
      sum += account.balance if account.classification == :liability
      sum
    end
  end

  # TODO: Replace test data with calculation
  def net_worth_series(period)
    series_data = accounts.includes(:balances).each_with_object({}) do |account, hash|
      account.balances.in_period(period).each do |balance|
        hash[balance.date] ||= 0
        if account.classification == :asset
          hash[balance.date] += balance.balance
        elsif account.classification == :liability
          hash[balance.date] -= balance.balance
        end
      end
    end.map do |date, balance|
      { date: date, balance: balance }
    end.sort_by { |data| data[:date] }


    MoneySeries.new(
      series_data,
      { trend_type: :asset }
    )
  end

  def asset_series(period)
    series_data = accounts.includes(:balances).each_with_object({}) do |account, hash|
      next unless account.classification == :asset
      account.balances.in_period(period).each do |balance|
        hash[balance.date] ||= 0
        hash[balance.date] += balance.balance
      end
    end.map do |date, balance|
      { date: date, value: balance }
    end.sort_by { |data| data[:date] }

    MoneySeries.new(
      series_data,
      { trend_type: :asset }
    )
  end

  def liability_series(period)
    series_data = accounts.includes(:balances).each_with_object({}) do |account, hash|
      next unless account.classification == :liability
      account.balances.in_period(period).each do |balance|
        hash[balance.date] ||= 0
        hash[balance.date] -= balance.balance
      end
    end.map do |date, balance|
      { date: date, value: balance }
    end.sort_by { |data| data[:date] }

    MoneySeries.new(
      series_data,
      { trend_type: :liability }
    )
  end
end
