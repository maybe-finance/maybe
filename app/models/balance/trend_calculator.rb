# The current system calculates a single, end-of-day balance every day for each account for simplicity.
# In most cases, this is sufficient.  However, for the "Activity View", we need to show intraday balances
# to show users how each entry affects their balances.  This class calculates intraday balances by
# interpolating between end-of-day balances.
class Balance::TrendCalculator
  BalanceTrend = Struct.new(:trend, :cash, keyword_init: true)

  def initialize(balances)
    @balances = balances
  end

  def trend_for(date)
    balance = @balances.find { |b| b.date == date }
    prior_balance = @balances.find { |b| b.date == date - 1.day }

    return BalanceTrend.new(trend: nil) unless balance.present?

    BalanceTrend.new(
      trend: Trend.new(
        current: Money.new(balance.balance, balance.currency),
        previous: Money.new(prior_balance.balance, balance.currency),
        favorable_direction: balance.account.favorable_direction
      ),
      cash: Money.new(balance.cash_balance, balance.currency),
    )
  end

  private
    attr_reader :balances
end
