class UI::Account::ActivityDate < ApplicationComponent
  attr_reader :account, :data

  delegate :date, :entries, :balance_trend, :cash_balance_trend, :holdings_value_trend, :transfers, to: :data

  def initialize(account:, data:)
    @account = account
    @data = data
  end

  def id
    dom_id(account, "entries_#{date}")
  end

  def broadcast_channel
    account
  end

  def start_balance_money
    balance_trend.previous
  end

  def cash_change_money
    cash_balance_trend.value
  end

  def holdings_change_money
    holdings_value_trend.value
  end

  def end_balance_before_adjustments_money
    balance_trend.previous + cash_change_money + holdings_change_money
  end

  def adjustments_money
    end_balance_money - end_balance_before_adjustments_money
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
