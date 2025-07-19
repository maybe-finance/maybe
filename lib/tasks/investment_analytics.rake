# lib/tasks/investment_analytics.rake

namespace :investment_analytics do
  desc "Syncs investment data from FMP for all or a specific account"
  task :sync, [:account_id] => :environment do |_, args|
    if ENV['ENABLE_INVESTMENT_ANALYTICS_APP'] != 'true'
      Rails.logger.warn("Investment Analytics app is not enabled. Set ENABLE_INVESTMENT_ANALYTICS_APP=true in your .env file.")
      exit 1
    end

    account_id = args[:account_id]

    if account_id.present?
      Rails.logger.info("Starting InvestmentAnalytics::SyncJob for account ID: #{account_id}")
      InvestmentAnalytics::SyncJob.perform_now(account_id: account_id)
    else
      Rails.logger.info("Starting InvestmentAnalytics::SyncJob for all active accounts with holdings.")
      InvestmentAnalytics::SyncJob.perform_now
    end
  rescue StandardError => e
    Rails.logger.error("InvestmentAnalytics: Sync job failed: #{e.message}")
    exit 1
  end
end
