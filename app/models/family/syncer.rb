class Family::Syncer
  attr_reader :family

  def initialize(family)
    @family = family
  end

  def child_syncables
    family.plaid_items + family.accounts.manual
  end

  def perform_sync(start_date: nil)
    # We don't rely on this value to guard the app, but keep it eventually consistent
    family.sync_trial_status!

    Rails.logger.info("Applying rules for family #{family.id}")
    family.rules.each do |rule|
      rule.apply_later
    end
  end

  def perform_post_sync
    family.auto_match_transfers!
    family.broadcast_refresh
  end
end
