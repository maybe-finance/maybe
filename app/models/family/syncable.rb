module Family::Syncable
  extend ActiveSupport::Concern

  include Syncable

  def sync_data(sync, start_date: nil)
    # We don't rely on this value to guard the app, but keep it eventually consistent
    sync_trial_status!

    Rails.logger.info("Syncing accounts for family #{id}")
    accounts.manual.each do |account|
      account.sync_later(start_date: start_date, parent_sync: sync)
    end

    Rails.logger.info("Syncing plaid items for family #{id}")
    plaid_items.each do |plaid_item|
      plaid_item.sync_later(start_date: start_date, parent_sync: sync)
    end

    Rails.logger.info("Applying rules for family #{id}")
    rules.each do |rule|
      rule.apply_later
    end
  end

  def remove_syncing_notice!
    broadcast_remove target: "syncing-notice"
  end

  def post_sync(sync)
    auto_match_transfers!
    broadcast_refresh
  end

  # If family has any syncs pending/syncing within the last 10 minutes, we show a persistent "syncing" notice.
  # Ignore syncs older than 10 minutes as they are considered "stale"
  def syncing?
    Sync.where(
      "(syncable_type = 'Family' AND syncable_id = ?) OR
       (syncable_type = 'Account' AND syncable_id IN (SELECT id FROM accounts WHERE family_id = ? AND plaid_account_id IS NULL)) OR
       (syncable_type = 'PlaidItem' AND syncable_id IN (SELECT id FROM plaid_items WHERE family_id = ?))",
      id, id, id
    ).where(status: [ "pending", "syncing" ], created_at: 10.minutes.ago..).exists?
  end
end
