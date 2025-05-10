class Family::Syncer
  attr_reader :family

  def initialize(family)
    @family = family
  end

  def perform_sync(sync, start_date: nil)
    # We don't rely on this value to guard the app, but keep it eventually consistent
    family.sync_trial_status!

    Rails.logger.info("Syncing accounts for family #{family.id}")
    family.accounts.manual.each do |account|
      account.sync_later(start_date: start_date, parent_sync: sync)
    end

    Rails.logger.info("Syncing plaid items for family #{family.id}")
    family.plaid_items.each do |plaid_item|
      plaid_item.sync_later(start_date: start_date, parent_sync: sync)
    end

    Rails.logger.info("Applying rules for family #{family.id}")
    family.rules.each do |rule|
      rule.apply_later
    end
  end

  def perform_post_sync(sync)
    family.auto_match_transfers!
    family.broadcast_refresh
  end
end
