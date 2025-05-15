class SyncMarketDataJob < ApplicationJob
  queue_as :scheduled

  def perform
    MarketDataSyncer.new.sync_all
  end
end
