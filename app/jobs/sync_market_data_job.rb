class SyncMarketDataJob < ApplicationJob
  queue_as :scheduled

  def perform(*args)
    syncer = MarketDataSyncer.new
    syncer.sync_exchange_rates
    syncer.sync_prices
  end
end
