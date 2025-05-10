module Account::Syncable
  extend ActiveSupport::Concern

  include Syncable

  def sync_data(sync, start_date: nil)
    Rails.logger.info("Processing balances (#{linked? ? 'reverse' : 'forward'})")
    sync_balances
  end

  def post_sync(sync)
    family.remove_syncing_notice!

    accountable.post_sync(sync)

    unless sync.child?
      family.auto_match_transfers!
    end
  end

  private
    def sync_balances
      strategy = linked? ? :reverse : :forward
      Balance::Syncer.new(self, strategy: strategy).sync_balances
    end
end
