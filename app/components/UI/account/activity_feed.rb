class UI::Account::ActivityFeed < ApplicationComponent
  attr_reader :feed_data, :pagy, :search

  def initialize(feed_data:, pagy:, search: nil)
    @feed_data = feed_data
    @pagy = pagy
    @search = search
  end

  def id
    dom_id(account, :activity_feed)
  end

  def broadcast_channel
    account
  end

  def broadcast_refresh!
    Turbo::StreamsChannel.broadcast_replace_to(
      broadcast_channel,
      target: id,
      renderable: self,
      layout: false
    )
  end

  def grouped_entries
    feed_data.entries.group_by(&:date).sort.reverse
  end

  def balance_trend_for_date(date)
    feed_data.trend_for_date(date)
  end

  def transfers_for_date(date)
    feed_data.transfers_for_date(date)
  end

  private
    def account
      feed_data.account
    end
end
