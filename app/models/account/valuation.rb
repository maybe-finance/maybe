class Account::Valuation < ApplicationRecord
  include Account::Entryable

  class << self
    def search(_params)
      all
    end

    def requires_search?(_params)
      false
    end
  end

  def name
    entry.name || (oldest? ? "Initial balance" : "Balance update")
  end

  def trend
    @trend ||= create_trend
  end

  def icon
    oldest? ? "plus" : entry.trend.icon
  end

  def color
    oldest? ? "#D444F1" : entry.trend.color
  end

  private
    def oldest?
      @oldest ||= account.entries.where("date < ?", entry.date).empty?
    end

    def account
      @account ||= entry.account
    end

    def create_trend
      TimeSeries::Trend.new(
        current: entry.amount_money,
        previous: prior_balance&.balance_money,
        favorable_direction: account.favorable_direction
      )
    end

    def prior_balance
      @prior_balance ||= account.balances
                               .where("date < ?", entry.date)
                               .order(date: :desc)
                               .first
    end
end
