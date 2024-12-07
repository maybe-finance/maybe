# The current system calculates a single, end-of-day balance every day for each account for simplicity.
# In most cases, this is sufficient.  However, for the "Activity View", we need to show intraday balances
# to show users how each entry affects their balances.  This class calculates intraday balances by
# interpolating between end-of-day balances.
class Account::BalanceTrendCalculator
  BalanceTrend = Struct.new(:trend, :cash, keyword_init: true)

  class << self 
    def for(entries)
      return nil if entries.blank?

      account = entries.first.account

      date_range = entries.minmax_by(&:date)
      min_entry_date, max_entry_date = date_range.map(&:date)

      entries_scope = account.entries.where(date: min_entry_date..max_entry_date)
      balances_scope = account.balances.where(date: (min_entry_date - 1.day)..max_entry_date)
      holdings_scope = account.holdings.where(date: (min_entry_date - 1.day)..max_entry_date)

      new(entries_scope, balances_scope, holdings_scope)
    end
  end

  def initialize(entries_scope, balances_scope, holdings_scope)
    @entries_scope = entries_scope
    @balances_scope = balances_scope
    @holdings_scope = holdings_scope
  end

  def trend_for(entry)
    intraday_balance = nil
    intraday_cash_balance = nil

    start_of_day_balance = ordered_balances.find { |b| b.date == entry.date - 1.day }
    end_of_day_balance = ordered_balances.find { |b| b.date == entry.date }

    return BalanceTrend.new(trend: nil) if start_of_day_balance.blank? || end_of_day_balance.blank?

    todays_holdings_value = holdings.select { |h| h.date == entry.date }.sum(&:amount)

    prior_balance = start_of_day_balance.balance
    prior_cash_balance = start_of_day_balance.cash_balance
    current_balance = nil
    current_cash_balance = nil

    todays_entries = ordered_entries.select { |e| e.date == entry.date }

    todays_entries.each_with_index do |e, idx|
      if e.account_valuation?
        current_balance = e.amount
        current_cash_balance = e.amount
      else
        multiplier = e.account.liability? ? 1 : -1
        balance_change = e.account_trade? ? 0 : multiplier * e.amount
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
      trend: TimeSeries::Trend.new(
        current: Money.new(intraday_balance, entry.currency),
        previous: Money.new(prior_balance, entry.currency),
        favorable_direction: entry.account.favorable_direction
      ),
      cash: Money.new(intraday_cash_balance, entry.currency),
    )
  end

  private
    attr_reader :balances_scope, :entries_scope, :holdings_scope, :entry

    def holdings
      @holdings ||= holdings_scope.to_a
    end

    def ordered_entries
      @ordered_entries ||= entries_scope.chronological.to_a
    end

    def ordered_balances
      @ordered_balances ||= balances_scope.chronological.to_a
    end
end
