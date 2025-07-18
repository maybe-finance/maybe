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

  def activity_dates
    feed_data.entries_by_date
  end

  private
    def account
      feed_data.account
    end
end
