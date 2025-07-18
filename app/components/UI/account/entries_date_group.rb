class UI::Account::EntriesDateGroup < ApplicationComponent
  attr_reader :account, :date, :entries, :balance_trend, :transfers

  def initialize(account:, date:, entries:, balance_trend:, transfers:)
    @account = account
    @date = date
    @entries = entries
    @balance_trend = balance_trend
    @transfers = transfers
  end

  def id
    dom_id(account, "entries_#{date}")
  end

  def broadcast_channel
    account
  end

  def valuation_entry
    entries.find { |entry| entry.entryable_type == "Valuation" }
  end

  def start_balance_money
    balance_trend.previous
  end

  def end_balance_before_adjustments_money
    balance_trend.previous + transaction_totals_money - holding_change_money
  end

  def adjustments_money
    end_balance_money - end_balance_before_adjustments_money
  end

  def transaction_totals_money
    transactions = entries.select { |e| e.transaction? }

    if transactions.any?
      transactions.sum { |e| e.amount_money } * -1
    else
      Money.new(0, account.currency)
    end
  end

  def holding_change_money
    trades = entries.select { |e| e.trade? }

    if trades.any?
      trades.sum { |e| e.amount_money } * -1
    else
      Money.new(0, account.currency)
    end
  end

  def end_balance_money
    balance_trend.current
  end

  def broadcast_refresh!
    Turbo::StreamsChannel.broadcast_replace_to(
      broadcast_channel,
      target: id,
      renderable: self,
      layout: false
    )
  end
end
