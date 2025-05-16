class Account::Syncer
  attr_reader :account

  def initialize(account)
    @account = account
  end

  def perform_sync(sync)
    Rails.logger.info("Processing balances (#{account.linked? ? 'reverse' : 'forward'})")
    sync_market_data
    sync_balances
  end

  def perform_post_sync
    account.family.auto_match_transfers!
  end

  private
    def sync_balances
      strategy = account.linked? ? :reverse : :forward
      Balance::Syncer.new(account, strategy: strategy).sync_balances
    end

    # Syncs all the exchange rates + security prices this account needs to display historical chart data
    #
    # This is a *supplemental* sync.  The daily market data sync should have already populated
    # a majority or all of this data, so this is often a no-op.
    #
    # We rescue errors here because if this operation fails, we don't want to fail the entire sync since
    # we have reasonable fallbacks for missing market data.
    def sync_market_data
      Account::MarketDataSyncer.new(account).sync_market_data
    rescue => e
      Rails.logger.error("Error syncing market data for account #{account.id}: #{e.message}")
      Sentry.capture_exception(e)
    end
end
