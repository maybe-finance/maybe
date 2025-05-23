class PlaidItem::Syncer
  attr_reader :plaid_item

  def initialize(plaid_item)
    @plaid_item = plaid_item
  end

  def perform_sync(sync)
    # Loads item metadata, accounts, transactions, and other data to our DB
    plaid_item.import_latest_plaid_data

    # Processes the raw Plaid data and updates internal domain objects
    plaid_item.process_accounts

    # All data is synced, so we can now run an account sync to calculate historical balances and more
    plaid_item.schedule_account_syncs(
      parent_sync: sync,
      window_start_date: sync.window_start_date,
      window_end_date: sync.window_end_date
    )
  end

  def perform_post_sync
    # no-op
  end
end
