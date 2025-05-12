class SyncMarketDataJob < ApplicationJob
  queue_as :scheduled

  def perform(*args)
    MarketDataSyncer.new.sync_all
  end
end
