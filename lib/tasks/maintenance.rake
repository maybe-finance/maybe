namespace :maintenance do
  desc "Quick Update"
  task :quick_update => :environment do
    Connection.all.each do |connection|
      SyncPlaidItemAccountsJob.perform(connection.item_id)
      SyncPlaidHoldingsJob.perform(connection.item_id)
      SyncPlaidInvestmentTransactionsJob.perform(connection.item_id)

      GenerateMetricsJob.perform_in(1.minute, connection.family_id)
    end

    EnrichTransactionsJob.perform

    # Sync security prices that haven't been synced in the last 24 hours or are nil
    Security.where("last_synced_at IS NULL OR last_synced_at < ?", 24.hours.ago).each do |security|
      SyncSecurityHistoryJob.perform(security.id)
    end

    # Sync security real time prices that haven't been synced in the last 30 minutes or are nil
    Security.where("real_time_price_updated_at IS NULL OR real_time_price_updated_at < ?", 30.minutes.ago).each do |security|
      RealTimeSyncJob.perform(security.id)
    end

    Account.all.each do |account|
      GenerateBalanceJob.perform(account.id)
    end

    Account.property.each do |account|
      SyncPropertyValuesJob.perform(account.id)
    end

    Family.all.each do |family|
      GenerateCategoricalMetricsJob.perform(family.id)
    end
  end

  desc "Institution Sync"
  task :institution_sync => :environment do
    SyncPlaidInstitutionsJob.perform_now
  end

  desc "Security Details Sync"
  task :security_details_sync => :environment do
    # Get Security where logo is nil
    Security.where(logo: nil).each do |security|
      SyncSecurityDetailsJob.perform(security.id)
    end
  end

  desc "Reset all connections"
  task :reset_connections => :environment do
    Transaction.delete_all
    Account.delete_all
    #Connection.delete_all
  end

  desc "Backfill balance changes"
  task :backfill_balance_changes => :environment do
    # Get each balance for each day and calculate the difference betweent "today" and the previous date available for that balance
    Balance.all.each do |balance|
      last_balance = Balance.where(account_id: balance.account_id, security_id: balance.security_id).where("date < ?", balance.date).order(date: :desc).limit(1).last&.balance

      if last_balance.present?
        balance.update(change: balance.balance - last_balance)
      end
    end
  end
end
