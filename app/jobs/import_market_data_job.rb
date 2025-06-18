# This job runs daily at market close.  See config/schedule.yml for details.
#
# The primary purpose of this job is to:
# 1. Determine what exchange rate pairs, security prices, and other market data all of our users need to view historical account balance data
# 2. For each needed rate/price, fetch from our data provider and upsert to our database
#
# Each individual account sync will still fetch any missing market data that isn't yet synced, but by running
# this job daily, we significantly reduce overlapping account syncs that both need the same market data (e.g. common security like `AAPL`)
#
class ImportMarketDataJob < ApplicationJob
  queue_as :scheduled

  def perform(opts)
    return if Rails.env.development?

    opts = opts.symbolize_keys
    mode = opts.fetch(:mode, :full)
    clear_cache = opts.fetch(:clear_cache, false)

    MarketDataImporter.new(mode: mode, clear_cache: clear_cache).import_all
  end
end
