class Account::Syncer
  attr_reader :account

  def initialize(account)
    @account = account
  end

  def perform_sync(sync)
    Rails.logger.info("Processing balances (#{account.linked? ? 'reverse' : 'forward'})")
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
end
