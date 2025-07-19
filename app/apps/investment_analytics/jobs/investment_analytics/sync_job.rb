# app/apps/investment_analytics/jobs/investment_analytics/sync_job.rb

module InvestmentAnalytics
  class SyncJob < InvestmentAnalytics::ApplicationJob
    queue_as :default # Or a specific queue if needed

    def perform(account_id: nil)
      fmp_provider = Provider::Registry.get_provider(:fmp)
      raise "FMP Provider not registered" unless fmp_provider

      # Determine which accounts to sync
      accounts = if account_id.present?
                   Account.where(id: account_id)
                 else
                   # Sync all accounts that have holdings and are active
                   Account.joins(:holdings).distinct.where(active: true)
                 end

      accounts.each do |account|
        Rails.logger.info("InvestmentAnalytics: Syncing data for account #{account.id} (#{account.name})")
        
        account.holdings.each do |holding|
          symbol = holding.security.ticker
          next unless symbol.present?

          begin
            # Fetch and update historical prices
            # This is a simplified example. In a real app, you'd manage
            # fetching only new data, handling pagination, etc.
            prices_data = fmp_provider.historical_prices(symbol)
            if prices_data.present?
              prices_data.each do |price_data|
                # Assuming Price model exists and has date, open, high, low, close, volume, currency
                # Maybe's Price model might need to be extended or a new one created
                # For now, we'll just log the update
                Rails.logger.debug("InvestmentAnalytics: Updating price for #{symbol} on #{price_data['date']}")
                # Example: Price.find_or_initialize_by(security: holding.security, date: price_data['date']).update!(
                #   open: price_data['open'], high: price_data['high'], low: price_data['low'],
                #   close: price_data['close'], volume: price_data['volume'], currency: price_data['currency']
                # )
              end
            end

            # Fetch and update historical dividends
            dividends_data = fmp_provider.historical_dividends(symbol)
            if dividends_data.present?
              dividends_data.each do |dividend_data|
                # Assuming Dividend model exists and has date, amount, currency
                # Maybe's Dividend model might need to be extended or a new one created
                Rails.logger.debug("InvestmentAnalytics: Updating dividend for #{symbol} on #{dividend_data['date']}")
                # Example: Dividend.find_or_initialize_by(security: holding.security, date: dividend_data['date']).update!(
                #   amount: dividend_data['dividend'], currency: dividend_data['currency']
                # )
              end
            end

          rescue Provider::Error => e
            Rails.logger.error("InvestmentAnalytics: FMP API error for #{symbol} in account #{account.id}: #{e.message}")
          rescue StandardError => e
            Rails.logger.error("InvestmentAnalytics: Unexpected error for #{symbol} in account #{account.id}: #{e.message}")
          end
        end
      end
      Rails.logger.info("InvestmentAnalytics: Sync job completed.")
    end
  end
end
