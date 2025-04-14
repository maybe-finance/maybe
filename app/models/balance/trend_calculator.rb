# The current system calculates a single, end-of-day balance every day for each account for simplicity.
# In most cases, this is sufficient.  However, for the "Activity View", we need to show intraday balances
# to show users how each entry affects their balances.  This class calculates intraday balances by
# interpolating between end-of-day balances.
class Balance::TrendCalculator
  BalanceTrend = Struct.new(:trend, :cash, keyword_init: true)

  class << self
    def for(entries)
      return nil if entries.blank?

      account = entries.first.account

      date_range = entries.minmax_by(&:date)
      min_entry_date, max_entry_date = date_range.map(&:date)

      # In case view is filtered and there are entry gaps, refetch all entries in range
      all_entries = account.entries.where(date: min_entry_date..max_entry_date).chronological.to_a
      balances = account.balances.where(date: (min_entry_date - 1.day)..max_entry_date).chronological.to_a
      holdings = account.holdings.where(date: (min_entry_date - 1.day)..max_entry_date).to_a

      new(all_entries, balances, holdings)
    end
  end

  def initialize(entries, balances, holdings)
    @entries = entries
    @balances = balances
    @holdings = holdings
  end

  def trend_for(entry)
    intraday_balance = nil
    intraday_cash_balance = nil

    start_of_day_balance = balances.find { |b| b.date == entry.date - 1.day && b.currency == entry.currency }
    end_of_day_balance = balances.find { |b| b.date == entry.date && b.currency == entry.currency }

    return BalanceTrend.new(trend: nil) if start_of_day_balance.blank? || end_of_day_balance.blank?

    todays_holdings_value = holdings.select { |h| h.date == entry.date }.sum(&:amount)

    prior_balance = start_of_day_balance.balance
    prior_cash_balance = start_of_day_balance.cash_balance
    current_balance = nil
    current_cash_balance = nil

    todays_entries = entries.select { |e| e.date == entry.date }

    todays_entries.each_with_index do |e, idx|
      if e.valuation?
        current_balance = e.amount
        current_cash_balance = e.amount
      else
        multiplier = e.account.liability? ? 1 : -1
        balance_change = e.trade? ? 0 : multiplier * e.amount
        cash_change = multiplier * e.amount

        current_balance = prior_balance + balance_change
        current_cash_balance = prior_cash_balance + cash_change
      end

      if e.id == entry.id
        # Final entry should always match the end-of-day balances
        if idx == todays_entries.size - 1
          intraday_balance = end_of_day_balance.balance
          intraday_cash_balance = end_of_day_balance.cash_balance
        else
          intraday_balance = current_balance
          intraday_cash_balance = current_cash_balance
        end

        break
      else
        prior_balance = current_balance
        prior_cash_balance = current_cash_balance
      end
    end

    return BalanceTrend.new(trend: nil) unless intraday_balance.present?

    BalanceTrend.new(
      trend: Trend.new(
        current: Money.new(intraday_balance, entry.currency),
        previous: Money.new(prior_balance, entry.currency),
        favorable_direction: entry.account.favorable_direction
      ),
      cash: Money.new(intraday_cash_balance, entry.currency),
    )
  end

  private
    attr_reader :entries, :balances, :holdings
end
